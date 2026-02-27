class AddSpotifyMetricsToArtists < ActiveRecord::Migration[8.1]
  def change
    change_table :artists, bulk: true do |t|
      t.integer :spotify_popularity
      t.integer :spotify_followers_count
    end
  end
end
