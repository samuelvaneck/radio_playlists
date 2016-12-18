class DropTablename < ActiveRecord::Migration
  def up
    drop_table :playlists
    drop_table :radio538playlists
    drop_table :radio2playlists
    drop_table :sublimefmplaylists
    drop_table :grootnieuwsplaylists
  end

  def down
    create_table :playlist do |t|
      t.integer  "radiostation_id"
      t.integer  "total_counter"
      t.string   "artist"
      t.string   "title"
      t.string   "image"
      t.string   "fullname"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "time"
      t.string   "date"
      t.integer  "day_counter"
      t.integer  "week_counter"
      t.integer  "month_counter"
      t.integer  "year_counter"

      t.timestamps
    end

    create_table :grootnieuwsplaylists do |t|
      t.string   "artist"
      t.string   "title"
      t.string   "image"
      t.string   "fullname"
      t.string   "time"
      t.string   "date"
      t.integer  "day_counter"
      t.integer  "week_counter"
      t.integer  "month_counter"
      t.integer  "year_counter"
      t.integer  "total_counter"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table :radio2playlist do |t|
      t.string   "artist"
      t.string   "title"
      t.string   "image"
      t.string   "fullname"
      t.string   "time"
      t.string   "date"
      t.integer  "day_counter"
      t.integer  "week_counter"
      t.integer  "month_counter"
      t.integer  "year_counter"
      t.integer  "total_counter"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table :radio538playlist do |t|
      t.string   "artist"
      t.string   "title"
      t.string   "image"
      t.string   "fullname"
      t.string   "time"
      t.string   "date"
      t.integer  "day_counter"
      t.integer  "week_counter"
      t.integer  "month_counter"
      t.integer  "year_counter"
      t.integer  "total_counter"
      t.integer  "radiostation_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table :sublimefmplaylist do |t|
      t.string   "artist"
      t.string   "title"
      t.string   "image"
      t.string   "fullname"
      t.string   "time"
      t.string   "date"
      t.integer  "day_counter"
      t.integer  "week_counter"
      t.integer  "month_counter"
      t.integer  "year_counter"
      t.integer  "total_counter"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index :playlists, :radiostation_id
  end

end
