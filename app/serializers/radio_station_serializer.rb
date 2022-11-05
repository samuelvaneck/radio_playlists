# frozen_string_literal: true

# serializer for radio_stations
class RadioStationSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id, :name
end
