# frozen_string_literal: true

# serializer for generaplaylist
class GeneralplaylistSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id, :broadcast_timestamp, :song_id, :radiostation_id, :created_at

  belongs_to :song
  belongs_to :radiostation
end
