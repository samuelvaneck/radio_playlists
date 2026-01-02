# frozen_string_literal: true

module Api
  module V1
    class RadioStationClassifiersController < ApiController
      def index
        profiles = if params[:radio_station_id].present?
                     radio_station = RadioStation.find(params[:radio_station_id])
                     calculator = RadioStationMusicProfileCalculator.new(
                       radio_station:,
                       day_part: params[:day_part]
                     )
                     calculator.calculate
                   else
                     RadioStation.all.flat_map do |rs|
                       calculator = RadioStationMusicProfileCalculator.new(radio_station: rs, day_part: params[:day_part])
                       profiles = calculator.calculate
                       profiles.map { |p| p.merge(radio_station: { id: rs.id, name: rs.name }) }
                     end
                   end

        render json: {
          data: profiles.map { |p| { type: 'radio_station_music_profile', attributes: p } },
          meta: { attribute_descriptions: MusicProfile::ATTRIBUTE_DESCRIPTIONS }
        }.to_json
      end

      def descriptions
        render json: { data: MusicProfile.attribute_descriptions }.to_json
      end
    end
  end
end
