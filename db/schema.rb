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

ActiveRecord::Schema.define(version: 20161007185854) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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

  add_foreign_key "playlists", "radiostations"
  add_foreign_key "radio538playlists", "radiostations"
end
