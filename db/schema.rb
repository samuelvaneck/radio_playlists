# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(:version => 2020_06_24_050809) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "artists", :force => :cascade do |t|
    t.string "name"
    t.string "image"
    t.string "genre"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string "spotify_artist_url"
    t.string "spotify_artwork_url"
  end

  create_table "artists_songs", :id => false, :force => :cascade do |t|
    t.bigint "song_id", :null => false
    t.bigint "artist_id", :null => false
    t.index ["artist_id"], :name => "index_artists_songs_on_artist_id"
    t.index ["song_id"], :name => "index_artists_songs_on_song_id"
  end

  create_table "generalplaylists", :force => :cascade do |t|
    t.bigint "song_id"
    t.bigint "radiostation_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.datetime "broadcast_timestamp"
    t.index ["radiostation_id"], :name => "index_generalplaylists_on_radiostation_id"
    t.index ["song_id", "radiostation_id", "broadcast_timestamp"], :name => "playlist_radio_song_time", :unique => true
    t.index ["song_id"], :name => "index_generalplaylists_on_song_id"
  end

  create_table "radiostations", :force => :cascade do |t|
    t.string "name"
    t.string "genre"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "songs", :force => :cascade do |t|
    t.string "title"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.text "fullname"
    t.string "spotify_song_url"
    t.string "spotify_artwork_url"
  end

  create_table "users", :force => :cascade do |t|
    t.string "email", :default => "", :null => false
    t.string "encrypted_password", :default => "", :null => false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", :default => 0, :null => false
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
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.index ["email"], :name => "index_users_on_email", :unique => true
    t.index ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  end

  add_foreign_key "generalplaylists", "radiostations"
  add_foreign_key "generalplaylists", "songs"
end
