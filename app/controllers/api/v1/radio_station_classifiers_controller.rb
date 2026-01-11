# frozen_string_literal: true

module Api
  module V1
    class RadioStationClassifiersController < ApiController
      VALID_TIME_PERIODS = %w[day week month year].freeze

      def index
        start_time, end_time = time_range_from_period

        hour = params[:hour].presence&.to_i

        profiles = if params[:radio_station_id].present?
                     radio_station = RadioStation.find(params[:radio_station_id])
                     calculator = RadioStationMusicProfileCalculator.new(
                       radio_station:,
                       hour:,
                       start_time:,
                       end_time:
                     )
                     calculator.calculate
                   else
                     RadioStation.all.flat_map do |rs|
                       calculator = RadioStationMusicProfileCalculator.new(
                         radio_station: rs,
                         hour:,
                         start_time:,
                         end_time:
                       )
                       profiles = calculator.calculate
                       profiles.map { |p| p.merge(radio_station: { id: rs.id, name: rs.name }) }
                     end
                   end

        render json: {
          data: profiles.map { |p| { type: 'radio_station_music_profile', attributes: p } },
          meta: { attribute_descriptions: RadioStationMusicProfileSerializer::AGGREGATED_ATTRIBUTE_DESCRIPTIONS }
        }.to_json
      end

      def descriptions
        render json: { data: RadioStationMusicProfileSerializer::AGGREGATED_ATTRIBUTE_DESCRIPTIONS }.to_json
      end

      private

      def time_range_from_period
        period = params[:time_period]
        return [nil, nil] if period.blank? || !VALID_TIME_PERIODS.include?(period)

        end_time = Time.current
        start_time = case period
                     when 'day' then 1.day.ago
                     when 'week' then 1.week.ago
                     when 'month' then 1.month.ago
                     when 'year' then 1.year.ago
                     end

        [start_time, end_time]
      end
    end
  end
end
