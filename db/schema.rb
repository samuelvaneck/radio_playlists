# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20161120150543) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "artists", force: :cascade do |t|
    t.string   "name"
    t.string   "image"
    t.string   "genre"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "artists_generalplaylists", force: :cascade do |t|
    t.integer "artist_id"
    t.integer "generalplaylist_id"
  end

  add_index "artists_generalplaylists", ["artist_id"], name: "index_artists_generalplaylists_on_artist_id", using: :btree
  add_index "artists_generalplaylists", ["generalplaylist_id"], name: "index_artists_generalplaylists_on_generalplaylist_id", using: :btree

  create_table "generalplaylists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "generalplaylists_radiostations", force: :cascade do |t|
    t.integer "generalplaylist_id"
    t.integer "radiostation_id"
  end

  add_index "generalplaylists_radiostations", ["generalplaylist_id"], name: "index_generalplaylists_radiostations_on_generalplaylist_id", using: :btree
  add_index "generalplaylists_radiostations", ["radiostation_id"], name: "index_generalplaylists_radiostations_on_radiostation_id", using: :btree

  create_table "generalplaylists_songs", force: :cascade do |t|
    t.integer "generalplaylist_id"
    t.integer "song_id"
  end

  add_index "generalplaylists_songs", ["generalplaylist_id"], name: "index_generalplaylists_songs_on_generalplaylist_id", using: :btree
  add_index "generalplaylists_songs", ["song_id"], name: "index_generalplaylists_songs_on_song_id", using: :btree

  create_table "grootnieuwsplaylists", force: :cascade do |t|
    t.string   "artist"
    t.string   "title"
    t.string   "image"
    t.string   "fullname"
    t.string   "time"
    t.string   "date"
    t.integer  "day_counter",   default: 0
    t.integer  "week_counter",  default: 0
    t.integer  "month_counter", default: 0
    t.integer  "year_counter",  default: 0
    t.integer  "total_counter", default: 0
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "playlists", force: :cascade do |t|
    t.integer  "radiostation_id"
    t.integer  "total_counter"
    t.string   "artist"
    t.string   "title"
    t.string   "image"
    t.string   "fullname"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "time"
    t.string   "date"
    t.integer  "day_counter"
    t.integer  "week_counter"
    t.integer  "month_counter"
    t.integer  "year_counter"
  end

  add_index "playlists", ["radiostation_id"], name: "index_playlists_on_radiostation_id", using: :btree

  create_table "radio2playlists", force: :cascade do |t|
    t.string   "artist"
    t.string   "title"
    t.string   "image"
    t.string   "fullname"
    t.string   "time"
    t.string   "date"
    t.integer  "day_counter",   default: 0
    t.integer  "week_counter",  default: 0
    t.integer  "month_counter", default: 0
    t.integer  "year_counter",  default: 0
    t.integer  "total_counter", default: 0
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "radio538playlists", force: :cascade do |t|
    t.string   "artist"
    t.string   "title"
    t.string   "image"
    t.string   "fullname"
    t.string   "time"
    t.string   "date"
    t.integer  "day_counter",     default: 0
    t.integer  "week_counter",    default: 0
    t.integer  "month_counter",   default: 0
    t.integer  "year_counter",    default: 0
    t.integer  "total_counter",   default: 0
    t.integer  "radiostation_id"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  add_index "radio538playlists", ["radiostation_id"], name: "index_radio538playlists_on_radiostation_id", using: :btree

  create_table "radiostations", force: :cascade do |t|
    t.string   "name"
    t.string   "genre"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "songs", force: :cascade do |t|
    t.string   "title"
    t.string   "album"
    t.string   "image"
    t.integer  "artist_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "songs", ["artist_id"], name: "index_songs_on_artist_id", using: :btree

  create_table "sublimefmplaylists", force: :cascade do |t|
    t.string   "artist"
    t.string   "title"
    t.string   "image"
    t.string   "fullname"
    t.string   "time"
    t.string   "date"
    t.integer  "day_counter",   default: 0
    t.integer  "week_counter",  default: 0
    t.integer  "month_counter", default: 0
    t.integer  "year_counter",  default: 0
    t.integer  "total_counter", default: 0
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_foreign_key "artists_generalplaylists", "artists"
  add_foreign_key "artists_generalplaylists", "generalplaylists"
  add_foreign_key "generalplaylists_radiostations", "generalplaylists"
  add_foreign_key "generalplaylists_radiostations", "radiostations"
  add_foreign_key "generalplaylists_songs", "generalplaylists"
  add_foreign_key "generalplaylists_songs", "songs"
  add_foreign_key "playlists", "radiostations"
  add_foreign_key "radio538playlists", "radiostations"
  add_foreign_key "songs", "artists"
end
