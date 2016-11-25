class AddCoutersToSong < ActiveRecord::Migration
  def change
    add_column :songs, :day_counter, :integer, :default => 0
    add_column :songs, :week_counter, :integer, :default => 0
    add_column :songs, :month_counter, :integer, :default => 0
    add_column :songs, :year_counter, :integer, :default => 0
    add_column :songs, :total_counter, :integer, :default => 0
  end
end
