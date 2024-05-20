# frozen_string_literal: true

module Api
  module V1
    class RadioStationsController < ApiController
      before_action :set_radio_station, except: %i[index]

      def index
        render json: RadioStationSerializer.new(RadioStation.all).serializable_hash.to_json
      end

      def show
        render json: RadioStationSerializer.new(@radio_station).serializable_hash.to_json
      end

      def status
        render json: @radio_station.status_data
      end

      private

      def set_radio_station
        @radio_station = RadioStation.find params[:id]
      end
    end
  end
end
