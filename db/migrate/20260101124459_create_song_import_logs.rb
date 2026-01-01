# frozen_string_literal: true

class CreateSongImportLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :song_import_logs do |t|
      # Associations
      t.references :radio_station, foreign_key: true, null: false
      t.references :song, foreign_key: true, null: true
      t.references :air_play, foreign_key: true, null: true

      # Recognition data (from SongRec audio fingerprinting)
      t.string :recognized_artist
      t.string :recognized_title
      t.string :recognized_isrc
      t.string :recognized_spotify_url
      t.jsonb :recognized_raw_response, default: {}

      # Scraped data (from radio station API)
      t.string :scraped_artist
      t.string :scraped_title
      t.string :scraped_isrc
      t.string :scraped_spotify_url
      t.jsonb :scraped_raw_response, default: {}

      # Source used for import
      t.string :import_source

      # Spotify lookup result
      t.string :spotify_artist
      t.string :spotify_title
      t.string :spotify_track_id
      t.string :spotify_isrc
      t.jsonb :spotify_raw_response, default: {}

      # Deezer lookup result
      t.string :deezer_artist
      t.string :deezer_title
      t.string :deezer_track_id
      t.jsonb :deezer_raw_response, default: {}

      # iTunes lookup result
      t.string :itunes_artist
      t.string :itunes_title
      t.string :itunes_track_id
      t.jsonb :itunes_raw_response, default: {}

      # Import metadata
      t.string :status, default: 'pending'
      t.text :failure_reason
      t.datetime :broadcasted_at

      t.timestamps
    end

    add_index :song_import_logs, :status
    add_index :song_import_logs, :broadcasted_at
    add_index :song_import_logs, :import_source
    add_index :song_import_logs, :created_at
  end
end
