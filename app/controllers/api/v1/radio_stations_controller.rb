# frozen_string_literal: true

module Api
  module V1
    class RadioStationsController < ApiController
      before_action :set_radio_station, only: %i[show status]

      def index
        render json: RadioStationSerializer.new(RadioStation.all).serializable_hash.to_json
      end

      def show
        render json: RadioStationSerializer.new(@radio_station).serializable_hash.to_json
      end

      def status
        render json: @radio_station.status_data
      end

      def last_played_songs
        render json: RadioStation.last_played_songs.to_json
      end

      def new_played_songs
        return render json: { error: 'Time parameter is required' }, status: :bad_request if time_param_blank?

        unless correct_time_params?
          error_message = 'Invalid time parameter. Possible values are day, week, month, year and all'
          return render json: { error: error_message }, status: :bad_request
        end

        new_played_songs = RadioStation.new_songs_played_for_period(params)
        render json: RadioStationSongSerializer.new(new_played_songs).serializable_hash.to_json
      end

      private

      def set_radio_station
        @radio_station = RadioStation.find params[:id]
      end

      def time_param_blank?
        params[:start_time].blank?
      end

      def correct_time_params?
        params[:start_time].in?(%w[day week month year all])
      end
    end
  end
end
