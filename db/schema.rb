# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170604201902) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "artists", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "image"
    t.string "genre"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "day_counter", default: 0
    t.integer "week_counter", default: 0
    t.integer "month_counter", default: 0
    t.integer "year_counter", default: 0
    t.integer "total_counter", default: 0
  end

  create_table "counters", id: :serial, force: :cascade do |t|
    t.integer "week"
    t.integer "month"
    t.integer "song_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["song_id"], name: "index_counters_on_song_id"
  end

  create_table "generalplaylists", id: :serial, force: :cascade do |t|
    t.string "time"
    t.integer "song_id"
    t.integer "radiostation_id"
    t.integer "artist_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["artist_id"], name: "index_generalplaylists_on_artist_id"
    t.index ["radiostation_id"], name: "index_generalplaylists_on_radiostation_id"
    t.index ["song_id"], name: "index_generalplaylists_on_song_id"
  end

  create_table "radiostations", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "genre"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "songs", id: :serial, force: :cascade do |t|
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "day_counter", default: 0
    t.integer "week_counter", default: 0
    t.integer "month_counter", default: 0
    t.integer "year_counter", default: 0
    t.integer "total_counter", default: 0
    t.integer "artist_id"
    t.text "fullname"
    t.text "song_preview"
    t.text "artwork_url"
    t.index ["artist_id"], name: "index_songs_on_artist_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.date "birthdate"
    t.string "country"
    t.string "display_name"
    t.string "followers"
    t.string "provider"
    t.string "uid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "counters", "songs"
  add_foreign_key "generalplaylists", "artists"
  add_foreign_key "generalplaylists", "radiostations"
  add_foreign_key "generalplaylists", "songs"
  add_foreign_key "songs", "artists"
end
