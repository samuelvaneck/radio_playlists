# frozen_string_literal: true

# == Schema Information
#
# Table name: song_import_logs
#
#  id                      :bigint           not null, primary key
#  acoustid_artist         :string
#  acoustid_raw_response   :jsonb
#  acoustid_score          :decimal(5, 4)
#  acoustid_title          :string
#  broadcasted_at          :datetime
#  deezer_artist           :string
#  deezer_raw_response     :jsonb
#  deezer_title            :string
#  failure_reason          :text
#  import_source           :string
#  itunes_artist           :string
#  itunes_raw_response     :jsonb
#  itunes_title            :string
#  recognized_artist       :string
#  recognized_isrc         :string
#  recognized_raw_response :jsonb
#  recognized_spotify_url  :string
#  recognized_title        :string
#  scraped_artist          :string
#  scraped_isrc            :string
#  scraped_raw_response    :jsonb
#  scraped_spotify_url     :string
#  scraped_title           :string
#  spotify_artist          :string
#  spotify_isrc            :string
#  spotify_raw_response    :jsonb
#  spotify_title           :string
#  status                  :string           default("pending")
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  acoustid_recording_id   :string
#  air_play_id             :bigint
#  deezer_track_id         :string
#  itunes_track_id         :string
#  radio_station_id        :bigint           not null
#  song_id                 :bigint
#  spotify_track_id        :string
#
# Indexes
#
#  index_song_import_logs_on_air_play_id       (air_play_id)
#  index_song_import_logs_on_broadcasted_at    (broadcasted_at)
#  index_song_import_logs_on_created_at        (created_at)
#  index_song_import_logs_on_import_source     (import_source)
#  index_song_import_logs_on_radio_station_id  (radio_station_id)
#  index_song_import_logs_on_song_id           (song_id)
#  index_song_import_logs_on_status            (status)
#
# Foreign Keys
#
#  fk_rails_...  (air_play_id => air_plays.id)
#  fk_rails_...  (radio_station_id => radio_stations.id)
#  fk_rails_...  (song_id => songs.id)
#
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
      it 'includes logs created before the given time' do
        expect(described_class.older_than(1.day.ago)).to include(old_log)
      end

      it 'excludes logs created after the given time' do
        expect(described_class.older_than(1.day.ago)).not_to include(recent_log)
      end
    end

    describe '.recent' do
      it 'includes logs from the last 24 hours' do
        expect(described_class.recent).to include(recent_log)
      end

      it 'excludes old logs' do
        expect(described_class.recent).not_to include(old_log)
      end
    end

    describe '.by_radio_station' do
      let(:radio_station) { create(:radio_station) }
      let!(:station_log) { create(:song_import_log, radio_station:) }

      it 'includes logs for the given station' do
        expect(described_class.by_radio_station(radio_station.id)).to include(station_log)
      end

      it 'excludes logs for other stations' do
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

    it 'includes log id in the CSV' do
      csv = described_class.to_csv(described_class.all)
      expect(csv).to include(log.id.to_s)
    end

    it 'includes recognized artist in the CSV' do
      csv = described_class.to_csv(described_class.all)
      expect(csv).to include(log.recognized_artist)
    end

    it 'includes spotify artist in the CSV' do
      csv = described_class.to_csv(described_class.all)
      expect(csv).to include(log.spotify_artist)
    end
  end
end
