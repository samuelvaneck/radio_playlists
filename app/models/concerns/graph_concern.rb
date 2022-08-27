# frozen_string_literal: true

module GraphConcern
  extend ActiveSupport::Concern

  STRFTIME_VALUES = {
    day: '%Y-%m-%dT%H:00',
    week: '%Y-%m-%d',
    month: '%Y-%m-%d',
    year: '%Y-%m-%d',
    all: '%Y-%m-%d'
  }.freeze
  TIME_STEPS = {
    day: 1.hour,
    week: 1.day,
    month: 1.day,
    year: 1.month,
    all: 1.month
  }.freeze

  included do
    def graph_data_series(playlists, min_date, max_date, time_value)
      strftime_value = STRFTIME_VALUES[time_value.to_sym]
      time_step = TIME_STEPS[time_value.to_sym]
      min_date_i = min_date.to_datetime.beginning_of_day.to_i
      max_date_i = max_date.to_datetime.end_of_day.to_i

      (min_date_i..max_date_i).step(time_step).map do |date|
        date = Time.zone.at(date).strftime(strftime_value)
        result = { date: }
        grouped_playlists = playlists[date]

        Radiostation.find_each do |radio_station|
          result[radio_station.name] = if grouped_playlists && grouped_playlists[radio_station.id]
                                         grouped_playlists[radio_station.id].count
                                       else
                                         0
                                       end
        end
        result
      end
    end
  end
end
