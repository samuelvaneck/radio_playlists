# frozen_string_literal: true

module Api
  module V1
    class RadioStationClassifiersController < ApiController
      rate_limit to: 30, within: 1.minute, by: -> { request.remote_ip },
                 with: -> { render json: { error: 'Rate limit exceeded' }, status: :too_many_requests }

      def index
        start_time, end_time = classifiers_time_range

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

      def classifiers_time_range
        normalized_params = normalize_time_params
        return [nil, nil] if normalized_params[:period].blank? && normalized_params[:start_time].blank?

        RadioStation.time_range_from_params(normalized_params, default_period: 'day')
      end

      def normalize_time_params
        period = params[:period] || params[:time_period]
        { period:, start_time: params[:start_time], end_time: params[:end_time] }
      end
    end
  end
end
