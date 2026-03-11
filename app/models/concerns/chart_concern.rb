module ChartConcern
  extend ActiveSupport::Concern

  # Returns chart positions for a given time period
  #
  # @param period [String] e.g. '3_days', '2_weeks', '6_months', 'year', 'all' (default: '1_month')
  # @return [Array<Hash>] array of hashes with keys date, position, and counts
  def chart_positions_for_period(period = '1_month')
    duration = PeriodParser.parse_duration(period)
    duration = 1.month if duration.nil? && period != 'all'

    start_date = duration ? Time.zone.today - duration : nil
    positions = chart_positions_in_range(start_date)

    format_positions(positions, start_date)
  end

  private

  def chart_positions_in_range(start_date)
    scope = chart_positions.joins(:chart).order('charts.date ASC')
    scope = scope.where('charts.date >= ?', start_date) if start_date
    scope.select('charts.date, chart_positions.position, chart_positions.counts')
  end

  def format_positions(positions, start_date)
    return [] if positions.empty?

    positions_by_date = positions.index_by { |p| p.date.to_s }
    min_date = start_date || positions.minimum(:date)
    max_date = Time.zone.yesterday

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
