class AddDeezerAndItunesFieldsToSongs < ActiveRecord::Migration[8.1]
  def change
    # Deezer fields
    add_column :songs, :id_on_deezer, :string
    add_column :songs, :deezer_song_url, :string
    add_column :songs, :deezer_artwork_url, :string
    add_column :songs, :deezer_preview_url, :string

    # iTunes fields
    add_column :songs, :id_on_itunes, :string
    add_column :songs, :itunes_song_url, :string
    add_column :songs, :itunes_artwork_url, :string
    add_column :songs, :itunes_preview_url, :string

    # Add indexes for lookup by external IDs
    add_index :songs, :id_on_deezer
    add_index :songs, :id_on_itunes
  end
end
