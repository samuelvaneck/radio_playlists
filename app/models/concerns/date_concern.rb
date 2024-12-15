# frozen_string_literal: true

module DateConcern
  extend ActiveSupport::Concern

  included do
    def self.date_from_params(time:, fallback:)
      return fallback if time.blank?
      return time if time.is_a?(Time)

      return 1.day.ago if time == 'day'
      return 1.week.ago if time == 'week'
      return 1.month.ago if time == 'month'
      return 1.year.ago if time == 'year'
      return 100.years.ago if time == 'all'

      Time.zone.strptime(time, '%Y-%m-%dT%R')
    end
  end
end
