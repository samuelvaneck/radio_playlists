# frozen_string_literal: true

module GraphConcern
  extend ActiveSupport::Concern

  STRFTIME_VALUES = {
    day: '%Y-%m-%dT%H:00',
    week: '%Y-%m-%d',
    month: '%Y-%m-%d',
    year: '%Y-%m',
    all: '%Y-%m'
  }.freeze

  included do
    def graph_data_series(playlists, min_date, max_date, strftime_value)
      min_date.to_date.upto(max_date.to_date).map do |date|
        date = date.strftime(strftime_value)
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
