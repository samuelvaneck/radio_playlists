# frozen_string_literal: true

# == Schema Information
#
# Table name: chart_positions
#
#  id                :bigint           not null, primary key
#  counts            :bigint           default(0), not null
#  positianable_type :string           not null
#  position          :bigint           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  chart_id          :bigint           not null
#  positianable_id   :bigint           not null
#
# Indexes
#
#  index_chart_positions_on_chart_id                               (chart_id)
#  index_chart_positions_on_positianable_id_and_positianable_type  (positianable_id,positianable_type)
#
# Foreign Keys
#
#  fk_rails_...  (chart_id => charts.id)
#
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
