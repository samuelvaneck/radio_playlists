# frozen_string_literal: true

module GraphConcern
  extend ActiveSupport::Concern

  included do
    def graph_data(period)
      aggregation = PeriodParser.aggregation_for(period)
      strftime_value = aggregation[:strftime]
      duration = PeriodParser.parse_duration(period)

      air_plays = get_air_plays(duration)
      min_date, max_date = min_max_date(air_plays, strftime_value)
      air_plays = format_graph_data(air_plays, strftime_value)
      air_plays = graph_data_series(air_plays, min_date, max_date, strftime_value, aggregation[:time_step])
      air_plays << legend_data_column
      air_plays
    end

    def get_air_plays(duration)
      end_date = 1.day.ago.end_of_day
      result = air_plays.where.not(broadcasted_at: nil)
      if duration
        begin_date = duration.ago.beginning_of_day
        result = result.where(air_plays_time_slot_query, begin_date, end_date)
      end
      result.order(:broadcasted_at)
    end

    def min_max_date(results, strftime_value)
      results.map { |result| result.broadcasted_at.strftime(strftime_value) }.minmax
    end

    def air_plays_time_slot_query
      'air_plays.created_at > ? AND air_plays.created_at < ?'
    end

    def format_graph_data(air_plays, strftime_value)
      air_plays.each_with_object({}) do |air_play, result|
        broadcasted_at, radio_station_id = air_play.values_at(:broadcasted_at, :radio_station_id)
        date_key = broadcasted_at.strftime(strftime_value)
        result[date_key] ||= {}
        result[date_key][radio_station_id] ||= 0
        result[date_key][radio_station_id] += 1
      end
    end

    def graph_data_series(air_plays, min_date, max_date, strftime_value, time_step)
      min_date_i = min_date.present? ? min_date.to_datetime.beginning_of_day.to_i : time_step.send(:ago).beginning_of_day.to_i
      max_date_i = max_date.present? ? max_date.to_datetime.end_of_day.to_i : Time.zone.now.end_of_day.to_i

      radio_stations = RadioStation.unscoped.pluck(:id, :name).to_h

      (min_date_i..max_date_i).step(time_step).map do |date|
        date = Time.zone.at(date).strftime(strftime_value)
        result = { date: }
        grouped_air_plays = air_plays[date]

        radio_stations.each do |radio_station_id, radio_station_name|
          result[radio_station_name] = grouped_air_plays&.dig(radio_station_id) || 0
        end
        result
      end
    end

    def legend_data_column
      { columns: RadioStation.unscoped.pluck(:name) }
    end
  end
end
