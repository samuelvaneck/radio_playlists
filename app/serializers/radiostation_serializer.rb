# frozen_string_literal: true

# serializer for radiostations
class RadiostationSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id, :name

  has_many :generalplaylists
  has_many :songs
  has_many :artists
end
