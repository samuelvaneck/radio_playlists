class AddIdOnSpotifyToSongsAndArtists < ActiveRecord::Migration[6.1]
  def change
    add_column :songs, :id_on_spotify, :string
    add_column :artists, :id_on_spotify, :string
  end
end
