# frozen_string_literal: true

module DateConcern
  extend ActiveSupport::Concern

  TIME_MAPPINGS = {
    'hour' => -> { 1.hour.ago },
    'two_hours' => -> { 2.hours.ago },
    'four_hours' => -> { 4.hours.ago },
    'eight_hours' => -> { 8.hours.ago },
    'twelve_hours' => -> { 12.hours.ago },
    'day' => -> { 1.day.ago },
    'week' => -> { 1.week.ago },
    'month' => -> { 1.month.ago },
    'year' => -> { 1.year.ago },
    'all' => -> { 100.years.ago }
  }.freeze

  included do
    def self.date_from_params(time:, fallback:)
      return fallback if time.blank?
      return time if time.is_a?(Time)

      TIME_MAPPINGS[time]&.() || Time.zone.strptime(time, '%Y-%m-%dT%R')
    end
  end
end
