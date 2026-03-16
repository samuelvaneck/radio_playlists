# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CombinedArtistSplitter do
  describe '#split' do
    let(:combined_artist) { create(:artist, name: 'David Guetta FT Sia') }
    let(:song) { create(:song) }

    before do
      ArtistsSong.create!(artist: combined_artist, song:)
    end

    context 'when individual artists do not exist yet' do
      it 'creates individual artists and reassigns songs', :aggregate_failures do
        result = described_class.new(combined_artist).split

        expect(result.map(&:name)).to contain_exactly('David Guetta', 'Sia')
        expect(Artist.find_by(name: 'David Guetta').songs).to include(song)
        expect(Artist.find_by(name: 'Sia').songs).to include(song)
        expect(Artist.find_by(id: combined_artist.id)).to be_nil
      end
    end

    context 'when individual artists already exist' do
      let!(:david_guetta) { create(:artist, name: 'David Guetta') }
      let!(:sia) { create(:artist, name: 'Sia') }

      it 'reuses existing artists', :aggregate_failures do
        result = described_class.new(combined_artist).split

        expect(result).to contain_exactly(david_guetta, sia)
        expect(david_guetta.songs.reload).to include(song)
        expect(sia.songs.reload).to include(song)
      end
    end

    context 'when an individual artist already has the song' do
      let!(:david_guetta) { create(:artist, name: 'David Guetta') }

      before do
        ArtistsSong.create!(artist: david_guetta, song:)
      end

      it 'does not create duplicate join records', :aggregate_failures do
        described_class.new(combined_artist).split

        expect(ArtistsSong.where(artist_id: david_guetta.id, song_id: song.id).count).to eq(1)
      end
    end

    context 'when combined artist has chart positions' do
      let(:chart) { create(:chart) }
      let!(:chart_position) { create(:chart_position, positianable: combined_artist, chart:) }

      it 'reassigns chart positions to individual artists', :aggregate_failures do
        described_class.new(combined_artist).split

        expect(ChartPosition.find_by(id: chart_position.id).positianable.name).to eq('David Guetta').or eq('Sia')
      end
    end

    context 'when artist name cannot be split' do
      let(:single_artist) { create(:artist, name: 'Madonna') }

      it 'raises an error' do
        expect { described_class.new(single_artist).split }.to raise_error(ArgumentError, /Could not split/)
      end
    end
  end
end
