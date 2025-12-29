# frozen_string_literal: true

require 'rails_helper'

describe Deezer::SongEnricher do
  subject(:enricher) { described_class.new(song) }

  let(:artist) { create(:artist, name: 'Taylor Swift') }

  describe '#enrich' do
    context 'when the song is found on Deezer by ISRC', :aggregate_failures, :use_vcr do
      let(:song) do
        # Create with placeholder values to skip after_commit callbacks, then clear them
        s = create(:song,
                   title: 'Shake It Off',
                   artists: [artist],
                   isrc: 'USCJY1431349',
                   id_on_deezer: 'placeholder',
                   id_on_itunes: 'placeholder')
        # rubocop:disable Rails/SkipsModelValidations
        s.update_columns(id_on_deezer: nil, deezer_song_url: nil, deezer_artwork_url: nil, deezer_preview_url: nil)
        # rubocop:enable Rails/SkipsModelValidations
        s
      end

      it 'enriches the song with Deezer data' do
        enricher.enrich
        song.reload

        expect(song.id_on_deezer).to be_present
        expect(song.deezer_song_url).to include('deezer.com')
        expect(song.deezer_artwork_url).to be_present
        expect(song.deezer_preview_url).to be_present
      end
    end

    context 'when the song is found by title and artist search', :aggregate_failures, :use_vcr do
      let(:song) do
        s = create(:song,
                   title: 'Shake It Off',
                   artists: [artist],
                   isrc: nil,
                   id_on_deezer: 'placeholder',
                   id_on_itunes: 'placeholder')
        # rubocop:disable Rails/SkipsModelValidations
        s.update_columns(id_on_deezer: nil, deezer_song_url: nil, deezer_artwork_url: nil, deezer_preview_url: nil)
        # rubocop:enable Rails/SkipsModelValidations
        s
      end

      it 'enriches using the search query' do
        enricher.enrich
        song.reload

        expect(song.id_on_deezer).to be_present
        expect(song.deezer_song_url).to include('deezer.com')
      end
    end

    context 'when the song already has Deezer data' do
      let(:song) do
        create(:song,
               title: 'Shake It Off',
               artists: [artist],
               id_on_deezer: '123456789',
               deezer_song_url: 'https://www.deezer.com/track/123456789',
               id_on_itunes: 'placeholder')
      end

      it 'does not update the song' do
        expect { enricher.enrich }.not_to(change { song.reload.id_on_deezer })
      end
    end

    context 'when the song is not found on Deezer', :use_vcr do
      let(:song) do
        s = create(:song,
                   title: 'Nonexistent Track That Does Not Exist XYZ999',
                   artists: [create(:artist, name: 'Unknown Artist XYZ123ABC')],
                   isrc: nil,
                   id_on_deezer: 'placeholder',
                   id_on_itunes: 'placeholder')
        s.update_columns(id_on_deezer: nil) # rubocop:disable Rails/SkipsModelValidations
        s
      end

      it 'does not update the song' do
        enricher.enrich
        song.reload

        expect(song.id_on_deezer).to be_nil
      end
    end
  end
end
