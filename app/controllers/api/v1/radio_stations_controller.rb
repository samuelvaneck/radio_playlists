# frozen_string_literal: true

module Api
  module V1
    class RadioStationsController < ApiController
      before_action :set_radio_station, only: %i[show status new_played_songs]

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

        new_played_songs = @radio_station.new_songs_played_for_period(params[:time])
        render json: SongSerializer.new(new_played_songs).serializable_hash.to_json
      end

      private

      def set_radio_station
        @radio_station = RadioStation.find params[:id]
      end

      def time_param_blank?
        params[:time].blank?
    end
  end
end
