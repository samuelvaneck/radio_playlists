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
class SongImportLogSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id,
             :status,
             :import_source,
             :broadcasted_at,
             :created_at,
             :failure_reason,
             :recognized_artist,
             :recognized_title,
             :recognized_isrc,
             :acoustid_artist,
             :acoustid_title,
             :acoustid_recording_id,
             :acoustid_score,
             :scraped_artist,
             :scraped_title,
             :scraped_isrc,
             :spotify_artist,
             :spotify_title,
             :spotify_track_id,
             :spotify_isrc,
             :deezer_artist,
             :deezer_title,
             :deezer_track_id,
             :itunes_artist,
             :itunes_title,
             :itunes_track_id

  attribute :radio_station do |object|
    { id: object.radio_station_id, name: object.radio_station&.name }
  end

  attribute :song do |object|
    next nil unless object.song

    { id: object.song_id, title: object.song.title }
  end

  attribute :air_play do |object|
    next nil unless object.air_play

    { id: object.air_play_id }
  end
end
