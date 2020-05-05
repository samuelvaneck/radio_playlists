# frozen_string_literal: true

# serializer for radiostations
class RadiostationSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id, :name
end
