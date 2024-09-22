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

ActiveRecord::Schema[7.2].define(version: 2024_09_22_134307) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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

  create_table "artists", force: :cascade do |t|
    t.string "name"
    t.string "image"
    t.string "genre"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "spotify_artist_url"
    t.string "spotify_artwork_url"
    t.string "id_on_spotify"
  end

  create_table "artists_songs", id: false, force: :cascade do |t|
    t.bigint "song_id", null: false
    t.bigint "artist_id", null: false
    t.index ["artist_id", "song_id"], name: "index_artists_songs_on_artist_id_and_song_id", unique: true
    t.index ["artist_id"], name: "index_artists_songs_on_artist_id"
    t.index ["song_id"], name: "index_artists_songs_on_song_id"
  end

  create_table "charts", force: :cascade do |t|
    t.datetime "date", precision: nil
    t.jsonb "chart", default: []
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
    t.integer "danceable"
    t.integer "energy"
    t.integer "speech"
    t.integer "acoustic"
    t.integer "instrumental"
    t.integer "live"
    t.integer "valance"
    t.string "day_part"
    t.jsonb "tags"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["radio_station_id"], name: "index_radio_station_classifiers_on_radio_station_id"
  end

  create_table "radio_station_songs", force: :cascade do |t|
    t.bigint "song_id", null: false
    t.bigint "radio_station_id", null: false
    t.datetime "first_broadcasted_at"
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

  create_table "song_recognizer_logs", force: :cascade do |t|
    t.bigint "radio_station_id", null: false
    t.integer "song_match"
    t.string "recognizer_song_fullname"
    t.string "api_song_fullname"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["radio_station_id"], name: "index_song_recognizer_logs_on_radio_station_id"
  end

  create_table "songs", force: :cascade do |t|
    t.string "title"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "fullname"
    t.string "spotify_song_url"
    t.string "spotify_artwork_url"
    t.string "id_on_spotify"
    t.string "isrc"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "playlists", "radio_stations"
  add_foreign_key "playlists", "songs"
  add_foreign_key "radio_station_classifiers", "radio_stations"
  add_foreign_key "radio_station_songs", "radio_stations"
  add_foreign_key "radio_station_songs", "songs"
  add_foreign_key "song_recognizer_logs", "radio_stations"
end
