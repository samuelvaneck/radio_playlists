# frozen_string_literal: true

module PeriodParser
  VALID_UNITS = %w[hour hours day days week weeks month months year years].freeze
  LEGACY_PERIODS = { 'hour' => '1_hour', 'day' => '1_day', 'week' => '1_week', 'month' => '1_month', 'year' => '1_year' }.freeze

  AGGREGATION_CONFIG = {
    hours: { strftime: '%Y-%m-%dT%H:%M', time_step: 10.minutes },
    days: { strftime: '%Y-%m-%dT%H:00', time_step: 1.hour },
    weeks: { strftime: '%Y-%m-%d', time_step: 1.day },
    months: { strftime: '%Y-%m-%d', time_step: 1.day },
    years: { strftime: '%Y-%m-01', time_step: 1.month }
  }.freeze

  class << self
    def parse_duration(period)
      return nil if period == 'all'

      period = normalize(period)
      number, unit = period.match(/\A(\d+)_(#{VALID_UNITS.join('|')})\z/)&.captures
      return nil unless number

      number.to_i.public_send(unit.to_sym)
    end

    def aggregation_for(period)
      return AGGREGATION_CONFIG[:years] if period == 'all'

      period = normalize(period)
      unit = period.match(/\A\d+_(#{VALID_UNITS.join('|')})\z/)&.captures&.first
      return AGGREGATION_CONFIG[:months] unless unit

      plural_unit = unit.to_s.pluralize.to_sym
      AGGREGATION_CONFIG[plural_unit] || AGGREGATION_CONFIG[:months]
    end

    private

    def normalize(period)
      LEGACY_PERIODS.fetch(period, period)
    end
  end
end
