# frozen_string_literal: true

module Api
  module V1
    class SongImportLogsController < ApiController
      def index
        render json: SongImportLogSerializer.new(song_import_logs)
                                            .serializable_hash
                                            .merge(pagination_data(song_import_logs))
                                            .to_json
      end

      private

      def song_import_logs
        @song_import_logs ||= SongImportLog.includes(:radio_station, :song, :air_play)
                                           .by_radio_station(params[:radio_station_id])
                                           .then { |scope| filter_by_status(scope) }
                                           .then { |scope| filter_by_import_source(scope) }
                                           .order(created_at: :desc)
                                           .paginate(page: params[:page], per_page: params[:per_page] || 25)
      end

      def filter_by_status(scope)
        return scope if params[:status].blank?

        scope.where(status: params[:status])
      end

      def filter_by_import_source(scope)
        return scope if params[:import_source].blank?

        scope.where(import_source: params[:import_source])
      end
    end
  end
end
