class AddSpotifyPreviewUrlToSongs < ActiveRecord::Migration[7.2]
  def change
    add_column :songs, :spotify_preview_url, :string
  end
end
