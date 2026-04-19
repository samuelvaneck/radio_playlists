# frozen_string_literal: true

require 'rails_helper'

describe MismatchedAirplayRepair do
  let(:radio_station) { create(:radio_station) }
  let(:artist) { create(:artist, name: 'Snelle') }
  let(:wrong_song) { create(:song, title: 'Ik Zing (feat. Snelle)', id_on_spotify: 'ikzing123', artists: [artist]) }
  let(:air_play) { create(:air_play, song: wrong_song, radio_station: radio_station) }

  describe '#run' do
    context 'when import log has mismatched title', :aggregate_failures do
      let!(:import_log) do
        create(:song_import_log,
               radio_station: radio_station,
               song: wrong_song,
               air_play: air_play,
               status: :success,
               scraped_artist: 'Snelle',
               scraped_title: 'Laat Het Licht Aan',
               spotify_artist: 'Snelle',
               spotify_title: 'Laat Het Licht Aan',
               spotify_track_id: 'laat123',
               import_source: :scraping)
      end

      context 'with dry_run: true' do
        let(:repair) { described_class.new(dry_run: true) }

        it 'detects the mismatch but does not fix it' do
          results = repair.run

          expect(results[:checked]).to eq(1)
          expect(results[:mismatched]).to eq(1)
          expect(results[:fixed]).to eq(0)
          expect(air_play.reload.song_id).to eq(wrong_song.id)
        end
      end

      context 'with dry_run: false' do
        let(:repair) { described_class.new(dry_run: false) }

        it 'creates a new song and reassigns the airplay' do
          results = repair.run

          expect(results[:mismatched]).to eq(1)
          expect(results[:fixed]).to eq(1)

          air_play.reload
          expect(air_play.song_id).not_to eq(wrong_song.id)
          expect(air_play.song.title).to eq('Laat Het Licht Aan')
          expect(air_play.song.id_on_spotify).to eq('laat123')
        end

        it 'updates the import log song reference' do
          repair.run

          import_log.reload
          expect(import_log.song_id).not_to eq(wrong_song.id)
          expect(import_log.song.title).to eq('Laat Het Licht Aan')
        end
      end
    end

    context 'when correct song already exists', :aggregate_failures do
      let!(:correct_song) { create(:song, title: 'Laat Het Licht Aan', id_on_spotify: 'laat123', artists: [artist]) }
      let(:import_log) do
        create(:song_import_log,
               radio_station: radio_station,
               song: wrong_song,
               air_play: air_play,
               status: :success,
               scraped_artist: 'Snelle',
               scraped_title: 'Laat Het Licht Aan',
               spotify_artist: 'Snelle',
               spotify_title: 'Laat Het Licht Aan',
               spotify_track_id: 'laat123',
               import_source: :scraping)
      end

      before { import_log }

      it 'reassigns to the existing song by spotify track id' do
        repair = described_class.new(dry_run: false)
        repair.run

        expect(air_play.reload.song).to eq(correct_song)
        expect(import_log.reload.song).to eq(correct_song)
      end

      it 'does not create a new song' do
        repair = described_class.new(dry_run: false)
        expect { repair.run }.not_to change(Song, :count)
      end
    end

    context 'when title matches correctly' do
      before do
        create(:song_import_log,
               radio_station: radio_station,
               song: wrong_song,
               air_play: air_play,
               status: :success,
               scraped_artist: 'Zoë Livay & Snelle',
               scraped_title: 'Ik Zing',
               spotify_artist: 'Zoë Livay, Snelle',
               spotify_title: 'Ik Zing (feat. Snelle)',
               spotify_track_id: 'ikzing123',
               import_source: :scraping)
      end

      it 'does not flag it as mismatched' do
        repair = described_class.new(dry_run: true)
        results = repair.run

        expect(results[:mismatched]).to eq(0)
      end
    end

    context 'when import log has no spotify data but has scraped data', :aggregate_failures do
      before do
        create(:song_import_log,
               radio_station: radio_station,
               song: wrong_song,
               air_play: air_play,
               status: :success,
               scraped_artist: 'Snelle',
               scraped_title: 'Laat Het Licht Aan',
               spotify_artist: nil,
               spotify_title: nil,
               spotify_track_id: nil,
               import_source: :scraping)
      end

      it 'detects mismatch using scraped title' do
        repair = described_class.new(dry_run: true)
        results = repair.run

        expect(results[:mismatched]).to eq(1)
      end
    end

    context 'when spotify_track_id points to a different canonical song' do
      let(:canonical_song) do
        create(:song, title: 'True Love (feat. Lily Allen)', id_on_spotify: 'truelove123', artists: [artist])
      end
      let(:lookalike_song) { create(:song, title: 'True Love', id_on_spotify: nil, artists: [artist]) }
      let(:air_play) { create(:air_play, song: lookalike_song, radio_station: radio_station) }
      let!(:import_log) do
        create(:song_import_log,
               radio_station: radio_station,
               song: lookalike_song,
               air_play: air_play,
               status: :success,
               scraped_artist: 'Pink & Lily Allen',
               scraped_title: 'True Love',
               spotify_artist: 'P!nk',
               spotify_title: 'True Love (feat. Lily Allen)',
               spotify_track_id: 'truelove123',
               import_source: :scraping)
      end

      before { canonical_song }

      it 'detects the spotify-id mismatch', :aggregate_failures do
        results = described_class.new(dry_run: true).run

        expect(results[:mismatched]).to eq(1)
        expect(results[:fixed]).to eq(0)
      end

      it 'reassigns the airplay to the canonical song', :aggregate_failures do
        described_class.new(dry_run: false).run

        expect(air_play.reload.song).to eq(canonical_song)
        expect(import_log.reload.song).to eq(canonical_song)
      end
    end

    context 'when spotify_track_id matches the linked song' do
      let(:wrong_song) do
        create(:song, title: 'True Love (feat. Lily Allen)', id_on_spotify: 'truelove123', artists: [artist])
      end

      before do
        create(:song_import_log,
               radio_station: radio_station,
               song: wrong_song,
               air_play: air_play,
               status: :success,
               scraped_artist: 'Pink & Lily Allen',
               scraped_title: 'True Love',
               spotify_title: 'True Love (feat. Lily Allen)',
               spotify_track_id: 'truelove123',
               import_source: :scraping)
      end

      it 'does not flag it as mismatched' do
        results = described_class.new(dry_run: true).run

        expect(results[:mismatched]).to eq(0)
      end
    end

    context 'when spotify_track_id has no canonical song' do
      before do
        create(:song_import_log,
               radio_station: radio_station,
               song: wrong_song,
               air_play: air_play,
               status: :success,
               scraped_artist: 'Zoë Livay & Snelle',
               scraped_title: 'Ik Zing',
               spotify_title: 'Ik Zing (feat. Snelle)',
               spotify_track_id: 'ikzing123',
               import_source: :scraping)
      end

      it 'does not flag it as mismatched' do
        results = described_class.new(dry_run: true).run

        expect(results[:mismatched]).to eq(0)
      end
    end

    context 'when import log has failed status' do
      before do
        create(:song_import_log,
               radio_station: radio_station,
               song: wrong_song,
               air_play: air_play,
               status: :failed,
               scraped_artist: 'Snelle',
               scraped_title: 'Laat Het Licht Aan',
               import_source: :scraping)
      end

      it 'skips non-success logs' do
        repair = described_class.new(dry_run: true)
        results = repair.run

        expect(results[:checked]).to eq(0)
      end
    end

    context 'with limit parameter' do
      before do
        3.times do
          ap = create(:air_play, song: wrong_song, radio_station: radio_station)
          create(:song_import_log,
                 radio_station: radio_station,
                 song: wrong_song,
                 air_play: ap,
                 status: :success,
                 spotify_title: 'Laat Het Licht Aan',
                 import_source: :scraping)
        end
      end

      it 'respects the limit' do
        repair = described_class.new(dry_run: true, limit: 2)
        results = repair.run

        expect(results[:checked]).to eq(2)
      end
    end
  end
end
