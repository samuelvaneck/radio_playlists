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

ActiveRecord::Schema[8.1].define(version: 2025_12_28_205453) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", precision: nil, null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admins", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.string "jti", null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.datetime "locked_at"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.string "uuid", default: "", null: false
    t.index ["email"], name: "index_admins_on_email", unique: true
    t.index ["jti"], name: "index_admins_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_admins_on_unlock_token", unique: true
    t.index ["uuid"], name: "index_admins_on_uuid", unique: true
  end

  create_table "air_plays", force: :cascade do |t|
    t.datetime "broadcasted_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.bigint "radio_station_id"
    t.boolean "scraper_import", default: false
    t.bigint "song_id"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["broadcasted_at"], name: "index_air_plays_on_broadcasted_at"
    t.index ["radio_station_id"], name: "index_air_plays_on_radio_station_id"
    t.index ["song_id", "radio_station_id", "broadcasted_at"], name: "air_play_radio_song_time", unique: true
    t.index ["song_id"], name: "index_air_plays_on_song_id"
  end

  create_table "artists", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "genre"
    t.string "id_on_spotify"
    t.string "image"
    t.string "instagram_url"
    t.string "name"
    t.string "spotify_artist_url"
    t.string "spotify_artwork_url"
    t.datetime "updated_at", precision: nil, null: false
    t.string "website_url"
    t.index ["name"], name: "index_artists_on_name"
  end

  create_table "artists_songs", id: false, force: :cascade do |t|
    t.bigint "artist_id", null: false
    t.bigint "song_id", null: false
    t.index ["artist_id", "song_id"], name: "index_artists_songs_on_artist_id_and_song_id", unique: true
    t.index ["artist_id"], name: "index_artists_songs_on_artist_id"
    t.index ["song_id"], name: "index_artists_songs_on_song_id"
  end

  create_table "chart_positions", force: :cascade do |t|
    t.bigint "chart_id", null: false
    t.bigint "counts", default: 0, null: false
    t.datetime "created_at", null: false
    t.bigint "positianable_id", null: false
    t.string "positianable_type", null: false
    t.bigint "position", null: false
    t.datetime "updated_at", null: false
    t.index ["chart_id"], name: "index_chart_positions_on_chart_id"
    t.index ["positianable_id", "positianable_type"], name: "index_chart_positions_on_positianable_id_and_positianable_type"
  end

  create_table "charts", force: :cascade do |t|
    t.string "chart_type"
    t.datetime "created_at", null: false
    t.date "date"
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_charts_on_date"
  end

  create_table "radio_station_classifiers", force: :cascade do |t|
    t.decimal "acousticness_average", precision: 5, scale: 3, default: "0.0"
    t.integer "counter", default: 0
    t.datetime "created_at", null: false
    t.decimal "danceability_average", precision: 5, scale: 3, default: "0.0"
    t.string "day_part", null: false
    t.decimal "energy_average", precision: 5, scale: 3, default: "0.0"
    t.decimal "high_acousticness_percentage", precision: 5, scale: 4, default: "0.0"
    t.decimal "high_danceability_percentage", precision: 5, scale: 4, default: "0.0"
    t.decimal "high_energy_percentage", precision: 5, scale: 4, default: "0.0"
    t.decimal "high_instrumentalness_percentage", precision: 5, scale: 4, default: "0.0"
    t.decimal "high_liveness_percentage", precision: 5, scale: 4, default: "0.0"
    t.decimal "high_speechiness_percentage", precision: 5, scale: 4, default: "0.0"
    t.decimal "high_valence_percentage", precision: 5, scale: 4, default: "0.0"
    t.decimal "instrumentalness_average", precision: 5, scale: 3, default: "0.0"
    t.decimal "liveness_average", precision: 5, scale: 3, default: "0.0"
    t.bigint "radio_station_id", null: false
    t.decimal "speechiness_average", precision: 5, scale: 3, default: "0.0"
    t.decimal "tempo", precision: 5, scale: 2, default: "0.0"
    t.datetime "updated_at", null: false
    t.decimal "valence_average", precision: 5, scale: 3, default: "0.0"
    t.index ["radio_station_id", "day_part"], name: "idx_on_radio_station_id_day_part_3fdb6160cd", unique: true
    t.index ["radio_station_id"], name: "index_radio_station_classifiers_on_radio_station_id"
  end

  create_table "radio_station_songs", force: :cascade do |t|
    t.datetime "first_broadcasted_at"
    t.bigint "radio_station_id", null: false
    t.bigint "song_id", null: false
    t.index ["first_broadcasted_at"], name: "index_radio_station_songs_on_first_broadcasted_at"
    t.index ["radio_station_id"], name: "index_radio_station_songs_on_radio_station_id"
    t.index ["song_id", "radio_station_id"], name: "index_radio_station_songs_on_song_id_and_radio_station_id", unique: true
    t.index ["song_id"], name: "index_radio_station_songs_on_song_id"
  end

  create_table "radio_stations", force: :cascade do |t|
    t.string "country_code"
    t.datetime "created_at", precision: nil, null: false
    t.string "genre"
    t.jsonb "last_added_air_play_ids"
    t.string "name"
    t.string "processor"
    t.string "slug"
    t.string "stream_url"
    t.datetime "updated_at", precision: nil, null: false
    t.text "url"
  end

  create_table "songs", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "id_on_spotify"
    t.string "id_on_youtube"
    t.string "isrc"
    t.date "release_date"
    t.string "release_date_precision"
    t.text "search_text"
    t.string "spotify_artwork_url"
    t.string "spotify_preview_url"
    t.string "spotify_song_url"
    t.string "title"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["release_date"], name: "index_songs_on_release_date"
    t.index ["search_text"], name: "index_songs_on_search_text"
  end

  create_table "tags", force: :cascade do |t|
    t.integer "counter", default: 0
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "taggable_id", null: false
    t.string "taggable_type", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "taggable_id", "taggable_type"], name: "index_tags_on_name_and_taggable_id_and_taggable_type", unique: true
    t.index ["taggable_type", "taggable_id"], name: "index_tags_on_taggable"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "air_plays", "radio_stations"
  add_foreign_key "air_plays", "songs"
  add_foreign_key "chart_positions", "charts"
  add_foreign_key "radio_station_classifiers", "radio_stations"
  add_foreign_key "radio_station_songs", "radio_stations"
  add_foreign_key "radio_station_songs", "songs"
end
