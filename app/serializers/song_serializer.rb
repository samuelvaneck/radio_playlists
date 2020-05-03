# frozen_string_literal: true

# serializer for songs
class SongSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id, :title, :artist_id, :fullname

  belongs_to :artist
  has_many :generalplaylists
  has_many :radiostations
end
