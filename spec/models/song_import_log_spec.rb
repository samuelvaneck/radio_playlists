# frozen_string_literal: true

describe SongImportLog do
  describe 'associations' do
    it { is_expected.to belong_to(:radio_station) }
    it { is_expected.to belong_to(:song).optional }
    it { is_expected.to belong_to(:air_play).optional }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:radio_station) }
  end

  describe 'enums' do
    describe 'status' do
      it 'defines the expected values' do
        expect(described_class.statuses).to eq({ 'pending' => 'pending', 'success' => 'success', 'failed' => 'failed', 'skipped' => 'skipped' })
      end
    end

    describe 'import_source' do
      it 'defines the expected values with prefix' do
        expect(described_class.import_sources).to eq({ 'recognition' => 'recognition', 'scraping' => 'scraping' })
      end

      it 'responds to prefixed methods' do
        log = build(:song_import_log, import_source: :recognition)
        expect(log.import_source_recognition?).to be true
      end
    end
  end

  describe 'scopes' do
    let!(:old_log) { create(:song_import_log, :old) }
    let!(:recent_log) { create(:song_import_log) }

    describe '.older_than' do
      it 'returns logs created before the given time' do
        expect(described_class.older_than(1.day.ago)).to include(old_log)
        expect(described_class.older_than(1.day.ago)).not_to include(recent_log)
      end
    end

    describe '.recent' do
      it 'returns logs from the last 24 hours' do
        expect(described_class.recent).to include(recent_log)
        expect(described_class.recent).not_to include(old_log)
      end
    end

    describe '.by_radio_station' do
      let(:radio_station) { create(:radio_station) }
      let!(:station_log) { create(:song_import_log, radio_station:) }

      it 'filters by radio station id' do
        expect(described_class.by_radio_station(radio_station.id)).to include(station_log)
        expect(described_class.by_radio_station(radio_station.id)).not_to include(old_log, recent_log)
      end

      it 'returns all logs when no id is provided' do
        expect(described_class.by_radio_station(nil)).to include(old_log, recent_log, station_log)
      end
    end
  end

  describe '.to_csv' do
    let!(:log) { create(:song_import_log, :with_recognition, :with_spotify) }

    it 'generates CSV with headers' do
      csv = described_class.to_csv(described_class.all)
      lines = csv.split("\n")

      expect(lines.first).to include('id', 'radio_station_id', 'recognized_artist', 'spotify_artist', 'status')
    end

    it 'includes log data in the CSV' do
      csv = described_class.to_csv(described_class.all)

      expect(csv).to include(log.id.to_s)
      expect(csv).to include(log.recognized_artist)
      expect(csv).to include(log.spotify_artist)
    end
  end
end
