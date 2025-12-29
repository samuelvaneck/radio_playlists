# frozen_string_literal: true

require 'rails_helper'

describe Itunes::SongEnricher do
  subject(:enricher) { described_class.new(song) }

  let(:artist) { create(:artist, name: 'Taylor Swift') }

  describe '#enrich' do
    context 'when the song is found on iTunes', :aggregate_failures, :use_vcr do
      let(:song) do
        # Create with placeholder values to skip after_commit callbacks, then clear them
        s = create(:song,
                   title: 'Shake It Off',
                   artists: [artist],
                   id_on_deezer: 'placeholder',
                   id_on_itunes: 'placeholder')
        # rubocop:disable Rails/SkipsModelValidations
        s.update_columns(id_on_itunes: nil, itunes_song_url: nil, itunes_artwork_url: nil, itunes_preview_url: nil)
        # rubocop:enable Rails/SkipsModelValidations
        s
      end

      it 'enriches the song with iTunes data' do
        enricher.enrich
        song.reload

        expect(song.id_on_itunes).to be_present
        expect(song.itunes_song_url).to include('music.apple.com')
        expect(song.itunes_artwork_url).to be_present
        expect(song.itunes_artwork_url).to include('600x600')
        expect(song.itunes_preview_url).to be_present
      end
    end

    context 'when the song already has iTunes data' do
      let(:song) do
        create(:song,
               title: 'Shake It Off',
               artists: [artist],
               id_on_deezer: 'placeholder',
               id_on_itunes: '123456789',
               itunes_song_url: 'https://music.apple.com/nl/album/shake-it-off/123456789')
      end

      it 'does not update the song' do
        expect { enricher.enrich }.not_to(change { song.reload.id_on_itunes })
      end
    end

    context 'when the song is not found on iTunes', :use_vcr do
      let(:song) do
        s = create(:song,
                   title: 'Nonexistent Track That Does Not Exist XYZ999',
                   artists: [create(:artist, name: 'Unknown Artist XYZ123ABC')],
                   id_on_deezer: 'placeholder',
                   id_on_itunes: 'placeholder')
        s.update_columns(id_on_itunes: nil) # rubocop:disable Rails/SkipsModelValidations
        s
      end

      it 'does not update the song' do
        enricher.enrich
        song.reload

        expect(song.id_on_itunes).to be_nil
      end
    end
  end
end
