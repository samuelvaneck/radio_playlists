class AddWikipediaUrlToSongsAndArtists < ActiveRecord::Migration[8.1]
  def change
    add_column :songs, :wikipedia_url, :string
    add_column :artists, :wikipedia_url, :string
  end
end
