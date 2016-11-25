class AddCoutersToArtist < ActiveRecord::Migration
  def change
    add_column :artists, :day_counter, :integer, :default => 0
    add_column :artists, :week_counter, :integer, :default => 0
    add_column :artists, :month_counter, :integer, :default => 0
    add_column :artists, :year_counter, :integer, :default => 0
    add_column :artists, :total_counter, :integer, :default => 0
  end
end
