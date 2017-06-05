class AddSpotifyUrlToSongs < ActiveRecord::Migration[5.1]
  def change
    add_column :songs, :spotify_song_url, :string
    add_column :songs, :spotify_artwork_url, :string
  end
end
