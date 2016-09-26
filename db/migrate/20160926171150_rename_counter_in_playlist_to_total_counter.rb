class RenameCounterInPlaylistToTotalCounter < ActiveRecord::Migration
  def change
    rename_column :playlists, :counter, :total_counter
  end
end
