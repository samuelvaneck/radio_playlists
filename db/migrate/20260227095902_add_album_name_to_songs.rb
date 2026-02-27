class AddAlbumNameToSongs < ActiveRecord::Migration[8.1]
  def change
    add_column :songs, :album_name, :string
  end
end
