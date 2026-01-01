# frozen_string_literal: true

# == Schema Information
#
# Table name: song_import_logs
#
#  id                       :bigint           not null, primary key
#  broadcasted_at           :datetime
#  deezer_artist            :string
#  deezer_raw_response      :jsonb
#  deezer_title             :string
#  deezer_track_id          :string
#  failure_reason           :text
#  import_source            :string
#  itunes_artist            :string
#  itunes_raw_response      :jsonb
#  itunes_title             :string
#  itunes_track_id          :string
#  recognized_artist        :string
#  recognized_isrc          :string
#  recognized_raw_response  :jsonb
#  recognized_spotify_url   :string
#  recognized_title         :string
#  scraped_artist           :string
#  scraped_isrc             :string
#  scraped_raw_response     :jsonb
#  scraped_spotify_url      :string
#  scraped_title            :string
#  spotify_artist           :string
#  spotify_isrc             :string
#  spotify_raw_response     :jsonb
#  spotify_title            :string
#  spotify_track_id         :string
#  status                   :string           default("pending")
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  air_play_id              :bigint
#  radio_station_id         :bigint           not null
#  song_id                  :bigint
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

class SongImportLog < ApplicationRecord
  CSV_COLUMNS = %w[
    id radio_station_id song_id air_play_id
    recognized_artist recognized_title recognized_isrc recognized_spotify_url
    scraped_artist scraped_title scraped_isrc scraped_spotify_url
    import_source
    spotify_artist spotify_title spotify_track_id spotify_isrc
    deezer_artist deezer_title deezer_track_id
    itunes_artist itunes_title itunes_track_id
    status failure_reason broadcasted_at created_at updated_at
  ].freeze

  belongs_to :radio_station
  belongs_to :song, optional: true
  belongs_to :air_play, optional: true

  enum :status, { pending: 'pending', success: 'success', failed: 'failed', skipped: 'skipped' }
  enum :import_source, { recognition: 'recognition', scraping: 'scraping' }, prefix: true

  validates :radio_station, presence: true

  scope :older_than, ->(time) { where(created_at: ...time) }
  scope :recent, -> { where(created_at: 24.hours.ago..) }
  scope :by_radio_station, ->(radio_station_id) { where(radio_station_id:) if radio_station_id.present? }

  def self.to_csv(logs)
    require 'csv'

    CSV.generate(headers: true) do |csv|
      csv << CSV_COLUMNS
      logs.find_each do |log|
        csv << CSV_COLUMNS.map { |col| log.send(col) }
      end
    end
  end
end
