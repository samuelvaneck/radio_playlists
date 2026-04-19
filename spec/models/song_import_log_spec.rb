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
#  llm_action              :string
#  llm_raw_response        :jsonb
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

    describe '.by_song' do
      let(:song) { create(:song) }
      let!(:linked_log) { create(:song_import_log, song:) }

      it 'filters by song_id', :aggregate_failures do
        result = described_class.by_song(song.id)
        expect(result).to include(linked_log)
        expect(result).not_to include(old_log, recent_log)
      end

      it 'returns all logs when blank' do
        expect(described_class.by_song(nil)).to include(old_log, recent_log, linked_log)
      end
    end

    describe '.by_status' do
      let!(:success_log) { create(:song_import_log, status: :success) }

      it 'filters by status', :aggregate_failures do
        result = described_class.by_status('success')
        expect(result).to include(success_log)
        expect(result).not_to include(old_log, recent_log)
      end

      it 'returns all logs when blank' do
        expect(described_class.by_status(nil)).to include(old_log, recent_log, success_log)
      end
    end

    describe '.by_import_source' do
      let!(:recognition_log) { create(:song_import_log, :with_recognition) }
      let!(:scraping_log) { create(:song_import_log, :with_scraping) }

      it 'filters by import_source', :aggregate_failures do
        result = described_class.by_import_source('recognition')
        expect(result).to include(recognition_log)
        expect(result).not_to include(scraping_log)
      end

      it 'returns all logs when blank' do
        expect(described_class.by_import_source(nil)).to include(recognition_log, scraping_log)
      end
    end

    describe '.by_llm_action' do
      let!(:cleanup_log) { create(:song_import_log, llm_action: 'track_name_cleanup') }

      it 'filters by llm_action', :aggregate_failures do
        result = described_class.by_llm_action('track_name_cleanup')
        expect(result).to include(cleanup_log)
        expect(result).not_to include(old_log, recent_log)
      end

      it 'returns all logs when blank' do
        expect(described_class.by_llm_action(nil)).to include(old_log, recent_log, cleanup_log)
      end
    end

    describe '.created_from' do
      it 'includes logs created at or after the given time', :aggregate_failures do
        result = described_class.created_from(1.day.ago)
        expect(result).to include(recent_log)
        expect(result).not_to include(old_log)
      end

      it 'accepts ISO8601 string input', :aggregate_failures do
        result = described_class.created_from(1.day.ago.iso8601)
        expect(result).to include(recent_log)
        expect(result).not_to include(old_log)
      end

      it 'is inclusive on the lower bound' do
        boundary_time = 1.day.ago
        boundary = create(:song_import_log, created_at: boundary_time)
        expect(described_class.created_from(boundary_time)).to include(boundary)
      end

      it 'returns all logs when blank' do
        expect(described_class.created_from(nil)).to include(old_log, recent_log)
      end
    end

    describe '.created_until' do
      it 'includes logs created at or before the given time', :aggregate_failures do
        result = described_class.created_until(1.day.ago)
        expect(result).to include(old_log)
        expect(result).not_to include(recent_log)
      end

      it 'is inclusive on the upper bound' do
        boundary_time = 1.day.ago
        boundary = create(:song_import_log, created_at: boundary_time)
        expect(described_class.created_until(boundary_time)).to include(boundary)
      end

      it 'returns all logs when blank' do
        expect(described_class.created_until(nil)).to include(old_log, recent_log)
      end
    end

    describe '.broadcasted_from and .broadcasted_until' do
      let!(:old_broadcast) { create(:song_import_log, broadcasted_at: 3.days.ago) }
      let!(:recent_broadcast) { create(:song_import_log, broadcasted_at: 1.hour.ago) }

      it 'broadcasted_from filters by lower bound', :aggregate_failures do
        result = described_class.broadcasted_from(2.days.ago)
        expect(result).to include(recent_broadcast)
        expect(result).not_to include(old_broadcast)
      end

      it 'broadcasted_until filters by upper bound', :aggregate_failures do
        result = described_class.broadcasted_until(2.days.ago)
        expect(result).to include(old_broadcast)
        expect(result).not_to include(recent_broadcast)
      end

      it 'combined they produce a range', :aggregate_failures do
        result = described_class.broadcasted_from(2.days.ago).broadcasted_until(30.minutes.ago)
        expect(result).to include(recent_broadcast)
        expect(result).not_to include(old_broadcast)
      end

      it 'both return all logs when blank' do
        scope = described_class.broadcasted_from(nil).broadcasted_until(nil)
        expect(scope).to include(old_broadcast, recent_broadcast)
      end
    end

    describe '.linked' do
      let(:song) { create(:song) }
      let!(:linked_log) { create(:song_import_log, song:) }
      let!(:unlinked_log) { create(:song_import_log, song: nil) }

      context 'when true' do
        it 'includes only logs with a song', :aggregate_failures do
          result = described_class.linked(true)
          expect(result).to include(linked_log)
          expect(result).not_to include(unlinked_log)
        end

        it 'coerces string "true"', :aggregate_failures do
          result = described_class.linked('true')
          expect(result).to include(linked_log)
          expect(result).not_to include(unlinked_log)
        end
      end

      context 'when false' do
        it 'includes only logs without a song', :aggregate_failures do
          result = described_class.linked(false)
          expect(result).to include(unlinked_log)
          expect(result).not_to include(linked_log)
        end

        it 'coerces string "false"', :aggregate_failures do
          result = described_class.linked('false')
          expect(result).to include(unlinked_log)
          expect(result).not_to include(linked_log)
        end
      end

      it 'returns all logs when blank' do
        expect(described_class.linked(nil)).to include(linked_log, unlinked_log)
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
