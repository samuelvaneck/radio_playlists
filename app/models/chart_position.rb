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
class ChartPosition < ApplicationRecord
  belongs_to :positianable, polymorphic: true
  belongs_to :chart

  validates :position, :positianable_id, :positianable_type, presence: true

  def self.item_position_on_day(item, date)
    chart = Chart.find_by(date: date)
    return 0 unless chart

    chart.chart_positions.find_by(positianable: item)&.position || 0
  end

  # returns the chart positions for an item on each day
  #
  # @item [Song | Artist] the item to get the chart positions for
  # @return [Array<Hash>] array of hashes with keys date and position
  def self.item_positions_with_date(item)
    chart_positions = item.chart_positions
    return [] if chart_positions.blank?

    min_date, max_date = chart_positions.joins(:chart).pluck('charts.date').minmax
    (min_date..max_date).map do |date|
      position = chart_positions.joins(:chart).find_by(charts: { date: date })&.position || 0
      counts = chart_positions.joins(:chart).find_by(charts: { date: date })&.counts || 0

      { date: date, position: position, counts: counts }
    end
  end
end
