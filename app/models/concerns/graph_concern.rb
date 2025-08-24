# frozen_string_literal: true

module GraphConcern
  extend ActiveSupport::Concern

  STRFTIME_VALUES = {
    day: '%Y-%m-%dT%H:00',
    week: '%Y-%m-%d',
    month: '%Y-%m-%d',
    year: '%Y-%m-01',
    all: '%Y-%m-01'
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
      air_plays = get_air_plays(time_value)
      min_date, max_date = min_max_date(air_plays, strftime_value)
      air_plays = format_graph_data(air_plays, strftime_value)
      air_plays = graph_data_series(air_plays, min_date, max_date, time_value)
      air_plays << legend_data_column
      air_plays
    end

    def get_air_plays(time_value)
      begin_date = graph_begin_date(time_value) unless time_value == 'all'
      end_date = 1.day.ago.end_of_day
      result = air_plays
      result = result.where(air_plays_time_slot_query, begin_date, end_date) unless time_value == 'all'
      result.sort_by(&:broadcasted_at)
    end

    def min_max_date(results, strftime_value)
      results.map { |result| result.broadcasted_at.strftime(strftime_value) }.minmax
    end

    def graph_begin_date(time_value)
      1.send(time_value.to_sym).ago.beginning_of_day
    end

    def air_plays_time_slot_query
      'air_plays.created_at > ? AND air_plays.created_at < ?'
    end

    def format_graph_data(air_plays, strftime_value)
      # result['2022-01-01'][radio_station_id]'] = 1
      air_plays.each_with_object({}) do |air_play, result|
        broadcasted_at, radio_station_id = air_play.values_at(:broadcasted_at, :radio_station_id)
        result[broadcasted_at.strftime(strftime_value)] ||= {}
        result[broadcasted_at.strftime(strftime_value)][radio_station_id] ||= []
        result[broadcasted_at.strftime(strftime_value)][radio_station_id] << air_play
      end
    end

    def graph_data_series(air_plays, min_date, max_date, time_value)
      strftime_value = STRFTIME_VALUES[time_value.to_sym]
      time_step = TIME_STEPS[time_value.to_sym]
      min_date_i = min_date.present? ? min_date.to_datetime.beginning_of_day.to_i : time_step.send(:ago).beginning_of_day.to_i
      max_date_i = max_date.present? ? max_date.to_datetime.end_of_day.to_i : Time.zone.now.end_of_day.to_i

      (min_date_i..max_date_i).step(time_step).map do |date|
        date = Time.zone.at(date).strftime(strftime_value)
        result = { date: }
        grouped_air_plays = air_plays[date]

        RadioStation.find_each do |radio_station|
          result[radio_station.name] = if grouped_air_plays && grouped_air_plays[radio_station.id]
                                         grouped_air_plays[radio_station.id].count
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
