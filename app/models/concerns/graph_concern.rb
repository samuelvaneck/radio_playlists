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
    def graph_data(time_value)
      strftime_value = STRFTIME_VALUES[time_value.to_sym]
      playlists = get_playlists(time_value)
      min_date, max_date = min_max_date(playlists, strftime_value)
      playlists = format_graph_data(playlists, strftime_value)
      playlists = graph_data_series(playlists, min_date, max_date, time_value)
      playlists << legend_data_column
      playlists
    end

    def get_playlists(time_value)
      begin_date = graph_begin_date(time_value) unless time_value == 'all'
      end_date = 1.day.ago.end_of_day
      result = playlists
      result = result.where(playlists_time_slot_query, begin_date, end_date) unless time_value == 'all'
      result.sort_by(&:broadcast_timestamp)
    end

    def min_max_date(results, strftime_value)
      results.map { |result| result.broadcast_timestamp.strftime(strftime_value) }.minmax
    end

    def graph_begin_date(time_value)
      1.send(time_value.to_sym).ago.send("beginning_of_#{time_value}".to_sym)
    end

    def playlists_time_slot_query
      'playlists.created_at > ? AND playlists.created_at < ?'
    end

    def format_graph_data(playlists, strftime_value)
      # result['2022-01-01'][radio_station_id]'] = 1
      playlists.each_with_object({}) do |playlist, result|
        broadcast_timestamp, radio_station_id = playlist.values_at(:broadcast_timestamp, :radio_station_id)
        result[broadcast_timestamp.strftime(strftime_value)] ||= {}
        result[broadcast_timestamp.strftime(strftime_value)][radio_station_id] ||= []
        result[broadcast_timestamp.strftime(strftime_value)][radio_station_id] << playlist
      end
    end

    def graph_data_series(playlists, min_date, max_date, time_value)
      strftime_value = STRFTIME_VALUES[time_value.to_sym]
      time_step = TIME_STEPS[time_value.to_sym]
      min_date_i = min_date.present? ? min_date.to_datetime.beginning_of_day.to_i : time_step.send(:ago).beginning_of_day.to_i
      max_date_i = max_date.present? ? max_date.to_datetime.end_of_day.to_i : Time.zone.now.end_of_day.to_i

      (min_date_i..max_date_i).step(time_step).map do |date|
        date = Time.zone.at(date).strftime(strftime_value)
        result = { date: }
        grouped_playlists = playlists[date]

        RadioStation.find_each do |radio_station|
          result[radio_station.name] = if grouped_playlists && grouped_playlists[radio_station.id]
                                         grouped_playlists[radio_station.id].count
                                       else
                                         0
                                       end
        end
        result
      end
    end

    def legend_data_column
      { columns: RadioStation.all.map(&:name) }
    end
  end
end
