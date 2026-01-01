# frozen_string_literal: true

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
