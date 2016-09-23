class AddTimeToPlaylist < ActiveRecord::Migration
  def change
    add_column :playlists, :time, :string
    add_column :playlists, :date, :string
  end
end
