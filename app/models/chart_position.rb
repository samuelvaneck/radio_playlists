# == Schema Information
#
# Table name: chart_positions
#
#  id                :bigint           not null, primary key
#  position          :bigint           not null
#  counts            :bigint           default(0), not null
#  positianable_id   :bigint           not null
#  positianable_type :string           not null
#  chart_id          :bigint           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
class ChartPosition < ApplicationRecord
  belongs_to :positianable, polymorphic: true
  belongs_to :chart

  validates :position, :positianable_id, :positianable_type, presence: true

  def self.item_position_on_day(item, date)
    chart = Chart.find_by(date: date)
    return -1 unless chart

    chart.chart_positions.find_by(positianable: item)&.position || -1
  end

  def self.item_positions_with_date(item)
    chart_positions = ChartPosition.where(positianable: item)
    chart_positions.map do |chart_position|
      { date: chart_position.chart.date, position: chart_position.position }
    end
  end
end