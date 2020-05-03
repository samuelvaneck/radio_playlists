# frozen_string_literal: true

# serializer for generaplaylist
class GeneralplaylistSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id, :time, :song_id, :radiostation_id, :artist_id

  belongs_to :song
  belongs_to :radiostation
  belongs_to :artist
end
