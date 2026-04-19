# frozen_string_literal: true

require 'rails_helper'

describe SongImportLogRollback do
  describe '#run' do
    let(:radio_station) { create(:radio_station) }
    let(:artist) { create(:artist, name: 'OCR Garbage Artist') }
    let(:song) { create(:song, title: 'OCR Garbage Title', artists: [artist]) }
    let(:air_play) { create(:air_play, song: song, radio_station: radio_station) }
    let(:import_log) do
      create(:song_import_log,
             radio_station: radio_station,
             song: song,
             air_play: air_play,
             status: :success,
             scraped_artist: 'OCR Garbage Artist',
             scraped_title: 'OCR Garbage Title',
             import_source: :scraping)
    end

    context 'with dry_run: true' do
      subject(:results) { described_class.new(import_log.id, dry_run: true).run }

      it 'reports what would happen without mutating', :aggregate_failures do
        expect(results[:air_play_destroyed]).to be true
        expect(results[:song_destroyed]).to be true
        expect(results[:errors]).to be_empty
        expect(AirPlay.exists?(air_play.id)).to be true
        expect(Song.exists?(song.id)).to be true
        expect(import_log.reload.status).to eq('success')
      end
    end

    context 'with dry_run: false and no other airplays' do
      subject(:results) { described_class.new(import_log.id, dry_run: false).run }

      before { results }

      it 'destroys the airplay and the song', :aggregate_failures do
        expect(AirPlay.exists?(air_play.id)).to be false
        expect(Song.exists?(song.id)).to be false
        expect(results[:air_play_destroyed]).to be true
        expect(results[:song_destroyed]).to be true
      end

      it 'marks the log as failed with rolled_back reason', :aggregate_failures do
        import_log.reload
        expect(import_log.status).to eq('failed')
        expect(import_log.failure_reason).to eq('rolled_back')
        expect(import_log.song_id).to be_nil
        expect(import_log.air_play_id).to be_nil
      end
    end

    context 'when the song has airplays from other stations' do
      subject(:results) { described_class.new(import_log.id, dry_run: false).run }

      let(:other_station) { create(:radio_station, name: 'Other Station') }
      let!(:other_air_play) { create(:air_play, song: song, radio_station: other_station) }

      it 'destroys only the targeted airplay and keeps the song', :aggregate_failures do
        expect(results[:air_play_destroyed]).to be true
        expect(results[:song_destroyed]).to be false
        expect(results[:song_kept_reason]).to eq('other_airplays_exist')
        expect(AirPlay.exists?(air_play.id)).to be false
        expect(AirPlay.exists?(other_air_play.id)).to be true
        expect(Song.exists?(song.id)).to be true
      end
    end

    context 'when the song has chart positions' do
      subject(:results) { described_class.new(import_log.id, dry_run: false).run }

      let!(:chart_position) { create(:chart_position, positianable: song) }

      it 'destroys airplay but keeps the song', :aggregate_failures do
        expect(results[:air_play_destroyed]).to be true
        expect(results[:song_destroyed]).to be false
        expect(results[:song_kept_reason]).to eq('has_chart_positions')
        expect(Song.exists?(song.id)).to be true
        expect(chart_position.reload).to be_present
      end
    end

    context 'when the log does not exist' do
      subject(:results) { described_class.new(999_999_999, dry_run: false).run }

      it 'returns an error result', :aggregate_failures do
        expect(results[:errors]).to include('import log not found')
        expect(results[:air_play_destroyed]).to be false
        expect(results[:song_destroyed]).to be false
      end
    end
  end
end
