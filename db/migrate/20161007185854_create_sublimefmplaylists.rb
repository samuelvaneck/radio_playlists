class CreateSublimefmplaylists < ActiveRecord::Migration
  def change
    create_table :sublimefmplaylists do |t|
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

      t.timestamps null: false
    end
  end
end
