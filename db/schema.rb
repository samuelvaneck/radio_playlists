# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_07_20_202928) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", precision: nil, null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admins", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "jti", null: false
    t.string "uuid", default: "", null: false
    t.index ["email"], name: "index_admins_on_email", unique: true
    t.index ["jti"], name: "index_admins_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_admins_on_unlock_token", unique: true
    t.index ["uuid"], name: "index_admins_on_uuid", unique: true
  end

  create_table "artists", force: :cascade do |t|
    t.string "name"
    t.string "image"
    t.string "genre"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "spotify_artist_url"
    t.string "spotify_artwork_url"
    t.string "id_on_spotify"
    t.jsonb "cached_chart_positions", default: []
    t.datetime "cached_chart_positions_updated_at"
    t.index ["name"], name: "index_artists_on_name"
  end

  create_table "artists_songs", id: false, force: :cascade do |t|
    t.bigint "song_id", null: false
    t.bigint "artist_id", null: false
    t.index ["artist_id", "song_id"], name: "index_artists_songs_on_artist_id_and_song_id", unique: true
    t.index ["artist_id"], name: "index_artists_songs_on_artist_id"
    t.index ["song_id"], name: "index_artists_songs_on_song_id"
  end

  create_table "chart_positions", force: :cascade do |t|
    t.bigint "position", null: false
    t.bigint "counts", default: 0, null: false
    t.bigint "positianable_id", null: false
    t.string "positianable_type", null: false
    t.bigint "chart_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chart_id"], name: "index_chart_positions_on_chart_id"
    t.index ["positianable_id", "positianable_type"], name: "index_chart_positions_on_positianable_id_and_positianable_type"
  end

  create_table "charts", force: :cascade do |t|
    t.date "date"
    t.string "chart_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "playlists", force: :cascade do |t|
    t.bigint "song_id"
    t.bigint "radio_station_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "broadcasted_at", precision: nil
    t.boolean "scraper_import", default: false
    t.index ["radio_station_id"], name: "index_playlists_on_radio_station_id"
    t.index ["song_id", "radio_station_id", "broadcasted_at"], name: "playlist_radio_song_time", unique: true
    t.index ["song_id"], name: "index_playlists_on_song_id"
  end

  create_table "radio_station_classifiers", force: :cascade do |t|
    t.bigint "radio_station_id", null: false
    t.string "day_part", null: false
    t.integer "danceability", default: 0
    t.decimal "danceability_average", precision: 5, scale: 3, default: "0.0"
    t.integer "energy", default: 0
    t.decimal "energy_average", precision: 5, scale: 3, default: "0.0"
    t.integer "speechiness", default: 0
    t.decimal "speechiness_average", precision: 5, scale: 3, default: "0.0"
    t.integer "acousticness", default: 0
    t.decimal "acousticness_average", precision: 5, scale: 3, default: "0.0"
    t.integer "instrumentalness", default: 0
    t.decimal "instrumentalness_average", precision: 5, scale: 3, default: "0.0"
    t.integer "liveness", default: 0
    t.decimal "liveness_average", precision: 5, scale: 3, default: "0.0"
    t.integer "valence", default: 0
    t.decimal "valence_average", precision: 5, scale: 3, default: "0.0"
    t.decimal "tempo", precision: 5, scale: 2, default: "0.0"
    t.integer "counter", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["radio_station_id", "day_part"], name: "idx_on_radio_station_id_day_part_3fdb6160cd", unique: true
    t.index ["radio_station_id"], name: "index_radio_station_classifiers_on_radio_station_id"
  end

  create_table "radio_station_songs", force: :cascade do |t|
    t.bigint "song_id", null: false
    t.bigint "radio_station_id", null: false
    t.datetime "first_broadcasted_at"
    t.index ["first_broadcasted_at"], name: "index_radio_station_songs_on_first_broadcasted_at"
    t.index ["radio_station_id"], name: "index_radio_station_songs_on_radio_station_id"
    t.index ["song_id", "radio_station_id"], name: "index_radio_station_songs_on_song_id_and_radio_station_id", unique: true
    t.index ["song_id"], name: "index_radio_station_songs_on_song_id"
  end

  create_table "radio_stations", force: :cascade do |t|
    t.string "name"
    t.string "genre"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "url"
    t.string "processor"
    t.string "stream_url"
    t.string "slug"
    t.string "country_code"
    t.jsonb "last_added_playlist_ids"
  end

  create_table "refresh_tokens", force: :cascade do |t|
    t.bigint "admin_id", null: false
    t.string "token", null: false
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_refresh_tokens_on_admin_id"
    t.index ["token"], name: "index_refresh_tokens_on_token", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "songs", force: :cascade do |t|
    t.string "title"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "search_text"
    t.string "spotify_song_url"
    t.string "spotify_artwork_url"
    t.string "id_on_spotify"
    t.string "isrc"
    t.string "spotify_preview_url"
    t.jsonb "cached_chart_positions", default: []
    t.datetime "cached_chart_positions_updated_at"
    t.string "id_on_youtube"
    t.index ["search_text"], name: "index_songs_on_search_text"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name", null: false
    t.integer "counter", default: 0
    t.string "taggable_type", null: false
    t.bigint "taggable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "taggable_id", "taggable_type"], name: "index_tags_on_name_and_taggable_id_and_taggable_type", unique: true
    t.index ["taggable_type", "taggable_id"], name: "index_tags_on_taggable"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "chart_positions", "charts"
  add_foreign_key "playlists", "radio_stations"
  add_foreign_key "playlists", "songs"
  add_foreign_key "radio_station_classifiers", "radio_stations"
  add_foreign_key "radio_station_songs", "radio_stations"
  add_foreign_key "radio_station_songs", "songs"
  add_foreign_key "refresh_tokens", "admins"
end
