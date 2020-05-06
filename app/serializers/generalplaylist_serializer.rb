# frozen_string_literal: true

# serializer for generaplaylist
class GeneralplaylistSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id, :time, :song_id, :radiostation_id, :artist_id, :created_at
end
