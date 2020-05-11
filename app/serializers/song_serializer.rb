# frozen_string_literal: true

# serializer for songs
class SongSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id,
             :title,
             :artist_id,
             :fullname,
             :spotify_song_url,
             :spotify_artwork_url

  has_many :songs
end
