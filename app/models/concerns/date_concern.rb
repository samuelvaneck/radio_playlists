# frozen_string_literal: true

module DateConcern
  extend ActiveSupport::Concern

  class ConflictingTimeParametersError < StandardError
    def message
      'Cannot provide both period and start_time/end_time parameters'
    end
  end

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

    def self.time_range_from_params(params, default_period: 'day')
      period = params[:period]
      start_time_param = params[:start_time]
      end_time_param = params[:end_time]

      raise ConflictingTimeParametersError if period.present? && start_time_param.present?

      if period.present?
        start_time = date_from_params(time: period, fallback: 1.day.ago)
        end_time = Time.zone.now
      else
        default_start = date_from_params(time: default_period, fallback: 1.day.ago)
        start_time = date_from_params(time: start_time_param, fallback: default_start)
        end_time = date_from_params(time: end_time_param, fallback: Time.zone.now)
      end

      [start_time, end_time]
    end
  end
end
