module ChartConcern
  extend ActiveSupport::Concern

  def update_cached_positions?
    cached_chart_positions_updated_at.nil? || cached_chart_positions_updated_at < 1.day.ago
  end

  def update_chart_positions
    update(cached_chart_positions: ChartPosition.item_positions_with_date(self),
           cached_chart_positions_updated_at: Time.zone.now)
  end
end
