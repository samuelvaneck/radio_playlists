class CreateRadio538Playlists < ActiveRecord::Migration
  def change
    create_table :radio_538_playlists do |t|
      t.string :artist
      t.string :title
      t.string :image
      t.string :fullname
      t.string :time
      t.string :date
      t.integer :day_counter, :default => 0
      t.integer :week_counter, :default => 0
      t.integer :month_counter, :default => 0
      t.integer :year_counter, :default => 0
      t.integer :total_counter, :default => 0
      t.references :radiostation, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
