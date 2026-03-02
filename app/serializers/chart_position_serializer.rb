# frozen_string_literal: true

class ChartPositionSerializer
  include FastJsonapi::ObjectSerializer

  set_type :chart_position

  attributes :position, :counts

  attribute :previous_position do |object, params|
    params[:previous_positions]&.dig(object.positianable_id)
  end

  attribute :song do |object|
    SongSerializer.new(object.positianable).serializable_hash[:data] if object.positianable_type == 'Song'
  end

  attribute :artist do |object|
    ArtistSerializer.new(object.positianable).serializable_hash[:data] if object.positianable_type == 'Artist'
  end
end
