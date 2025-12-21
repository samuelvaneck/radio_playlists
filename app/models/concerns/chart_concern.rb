module ChartConcern
  extend ActiveSupport::Concern

  PERIOD_RANGES = {
    'week' => 1.week,
    'month' => 1.month,
    'year' => 1.year,
    'all' => nil
  }.freeze

  def update_cached_positions?
    cached_chart_positions_updated_at.nil? || cached_chart_positions_updated_at < 1.day.ago
  end

  def update_chart_positions
    update(cached_chart_positions: ChartPosition.item_positions_with_date(self),
           cached_chart_positions_updated_at: Time.zone.now)
  end

  # Returns chart positions for a given time period
  #
  # @param period [String] one of 'week', 'month', 'year', 'all' (default: 'month')
  # @return [Array<Hash>] array of hashes with keys date, position, and counts
  def chart_positions_for_period(period = 'month')
    period = 'month' unless PERIOD_RANGES.key?(period)

    start_date = calculate_start_date(period)
    positions = chart_positions_in_range(start_date)

    format_positions(positions, start_date)
  end

  private

  def calculate_start_date(period)
    duration = PERIOD_RANGES[period]
    duration ? Time.zone.today - duration : nil
  end

  def chart_positions_in_range(start_date)
    scope = chart_positions.joins(:chart).order('charts.date ASC')
    scope = scope.where('charts.date >= ?', start_date) if start_date
    scope.select('charts.date, chart_positions.position, chart_positions.counts')
  end

  def format_positions(positions, start_date)
    return [] if positions.empty?

    positions_by_date = positions.index_by { |p| p.date.to_s }
    min_date = start_date || positions.minimum(:date)
    max_date = Time.zone.today

    (min_date..max_date).map do |date|
      position_record = positions_by_date[date.to_s]
      {
        date: date,
        position: position_record&.position || 0,
        counts: position_record&.counts || 0
      }
    end
  end
end
