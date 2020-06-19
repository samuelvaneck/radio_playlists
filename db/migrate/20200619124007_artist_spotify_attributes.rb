# frozen_string_literal: true

class ArtistSpotifyAttributes < ActiveRecord::Migration[6.0]
  def change
    add_column :artists, :spotify_artist_url, :string
    add_column :artists, :spotify_artwork_url, :string
  end
end
