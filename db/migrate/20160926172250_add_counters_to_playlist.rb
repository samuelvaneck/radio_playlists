class AddCountersToPlaylist < ActiveRecord::Migration
  def change
    add_column :playlists, :day_counter, :integer, :default => 0
    add_column :playlists, :week_counter, :integer, :default => 0
    add_column :playlists, :month_counter, :integer, :default => 0
    add_column :playlists, :year_counter, :integer, :default => 0
  end
end
