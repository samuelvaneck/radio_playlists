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

ActiveRecord::Schema.define(version: 2021_02_27_150050) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
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
    t.string "checksum", null: false
    t.datetime "created_at", null: false
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "spotify_artist_url"
    t.string "spotify_artwork_url"
    t.string "id_on_spotify"
  end

  create_table "artists_songs", id: false, force: :cascade do |t|
    t.bigint "song_id", null: false
    t.bigint "artist_id", null: false
    t.index ["artist_id"], name: "index_artists_songs_on_artist_id"
    t.index ["song_id"], name: "index_artists_songs_on_song_id"
  end

  create_table "generalplaylists", force: :cascade do |t|
    t.bigint "song_id"
    t.bigint "radiostation_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "broadcast_timestamp"
    t.index ["radiostation_id"], name: "index_generalplaylists_on_radiostation_id"
    t.index ["song_id", "radiostation_id", "broadcast_timestamp"], name: "playlist_radio_song_time", unique: true
    t.index ["song_id"], name: "index_generalplaylists_on_song_id"
  end

  create_table "radiostations", force: :cascade do |t|
    t.string "name"
    t.string "genre"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "url"
    t.string "processor"
  end

  create_table "songs", force: :cascade do |t|
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "fullname"
    t.string "spotify_song_url"
    t.string "spotify_artwork_url"
    t.string "id_on_spotify"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "generalplaylists", "radiostations"
  add_foreign_key "generalplaylists", "songs"
end
