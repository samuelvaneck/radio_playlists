# frozen_string_literal: true

# serializer for atists
class ArtistSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id, :name, :spotify_artist_url, :spotify_artwork_url

  has_many :songs
end
