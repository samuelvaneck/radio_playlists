# frozen_string_literal: true

# serializer for songs
class SongSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id,
             :title,
             :fullname,
             :spotify_song_url,
             :spotify_artwork_url,
             :artists

  def artists
    object.artists.map do |artist|
      ArtistSerializer.new(artist)
    end
  end
end
