# frozen_string_literal: true

# serializer for songs
class SongSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id,
             :title,
             :fullname,
             :artist_ids,
             :spotify_song_url,
             :spotify_artwork_url

  has_many :artists
end
