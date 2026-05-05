# frozen_string_literal: true

require 'rails_helper'

describe StuckPendingLogRecovery do
  let(:radio_station) { create(:radio_station) }
  let(:artist) { create(:artist, name: 'Luke Combs') }
  let(:broadcasted_at) { 30.minutes.ago }

  before do
    allow($stdout).to receive(:puts)
  end

  def stuck_log(overrides = {})
    log = create(:song_import_log,
                 radio_station: radio_station,
                 status: :pending,
                 broadcasted_at: broadcasted_at,
                 spotify_track_id: '1Lo0QY9cvc8sUB2vnIOxDT',
                 spotify_artist: 'Luke Combs',
                 spotify_title: 'Fast Car',
                 spotify_isrc: 'US6XF2200436',
                 recognized_artist: 'Luke Combs',
                 recognized_title: 'Fast Car',
                 import_source: :recognition,
                 **overrides)
    log.update_columns(created_at: 30.minutes.ago) # rubocop:disable Rails/SkipsModelValidations
    log
  end

  describe '#run' do
    context 'when the canonical Song already exists with the logged spotify_track_id' do
      let!(:song) { create(:song, title: 'Fast Car', id_on_spotify: '1Lo0QY9cvc8sUB2vnIOxDT', artists: [artist]) }
      let!(:log) { stuck_log }

      it 'creates an AirPlay and links it to the log', :aggregate_failures do
        results = described_class.new(dry_run: false).run

        log.reload
        expect(log.status).to eq('success')
        expect(log.song_id).to eq(song.id)
        expect(log.air_play_id).to be_present
        expect(log.air_play.song_id).to eq(song.id)
        expect(log.air_play.broadcasted_at).to be_within(1.second).of(broadcasted_at)
        expect(results).to include(checked: 1, recovered: 1, created_air_play: 1, reused_air_play: 0)
      end
    end

    context 'when an AirPlay was already created by the original interrupted import' do
      let!(:song) { create(:song, title: 'Fast Car', id_on_spotify: '1Lo0QY9cvc8sUB2vnIOxDT', artists: [artist]) }
      let!(:existing_air_play) do
        create(:air_play, song: song, radio_station: radio_station, broadcasted_at: broadcasted_at)
      end
      let!(:log) { stuck_log }

      it 'reuses the existing AirPlay instead of creating a duplicate', :aggregate_failures do
        results = described_class.new(dry_run: false).run

        log.reload
        expect(log.air_play_id).to eq(existing_air_play.id)
        expect(log.status).to eq('success')
        expect(AirPlay.where(song: song, radio_station: radio_station, broadcasted_at: broadcasted_at).count).to eq(1)
        expect(results).to include(recovered: 1, reused_air_play: 1, created_air_play: 0)
      end
    end

    context 'when no Song with the spotify_track_id exists yet' do
      let!(:log) { stuck_log }

      it 'creates the Song from log data and links the airplay', :aggregate_failures do
        artist
        results = described_class.new(dry_run: false).run

        log.reload
        expect(log.song.id_on_spotify).to eq('1Lo0QY9cvc8sUB2vnIOxDT')
        expect(log.song.title).to eq('Fast Car')
        expect(log.song.isrcs).to eq(['US6XF2200436'])
        expect(log.air_play.song_id).to eq(log.song_id)
        expect(results).to include(recovered: 1, created_air_play: 1)
      end
    end

    context 'when the log has no spotify_track_id' do
      let!(:log) { stuck_log(spotify_track_id: nil, spotify_artist: nil, spotify_title: nil, spotify_isrc: nil) }

      it 'leaves the log alone', :aggregate_failures do
        results = described_class.new(dry_run: false).run

        log.reload
        expect(log.status).to eq('pending')
        expect(results).to include(checked: 0)
      end
    end

    context 'when the log is younger than min_age' do
      let!(:log) do
        create(:song, title: 'Fast Car', id_on_spotify: '1Lo0QY9cvc8sUB2vnIOxDT', artists: [artist])
        log = stuck_log
        log.update_columns(created_at: 1.minute.ago) # rubocop:disable Rails/SkipsModelValidations
        log
      end

      it 'is excluded from recovery', :aggregate_failures do
        results = described_class.new(dry_run: false).run

        expect(log.reload.status).to eq('pending')
        expect(results).to include(checked: 0)
      end
    end

    context 'with dry_run: true' do
      let(:song) { create(:song, title: 'Fast Car', id_on_spotify: '1Lo0QY9cvc8sUB2vnIOxDT', artists: [artist]) }
      let!(:log) do
        song
        stuck_log
      end

      it 'reports what would happen without mutating', :aggregate_failures do
        results = described_class.new(dry_run: true).run

        log.reload
        expect(log.status).to eq('pending')
        expect(log.air_play_id).to be_nil
        expect(AirPlay.where(song: song).count).to eq(0)
        expect(results).to include(checked: 1, created_air_play: 0, recovered: 0)
      end
    end

    context 'when AirPlay creation fails (e.g., missing broadcasted_at)' do
      let!(:log) do
        create(:song, title: 'Fast Car', id_on_spotify: '1Lo0QY9cvc8sUB2vnIOxDT', artists: [artist])
        stuck_log(broadcasted_at: nil)
      end

      it 'records the error and leaves the log pending', :aggregate_failures do
        results = described_class.new(dry_run: false).run

        log.reload
        expect(log.status).to eq('pending')
        expect(results[:errors].count).to eq(1)
        expect(results[:errors].first[:log_id]).to eq(log.id)
      end
    end
  end
end
