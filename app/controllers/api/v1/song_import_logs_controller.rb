# frozen_string_literal: true

module Api
  module V1
    class SongImportLogsController < ApplicationController
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
                                .by_song(params[:song_id])
                                .by_status(params[:status])
                                .by_import_source(params[:import_source])
                                .by_llm_action(params[:llm_action])
                                .created_from(params[:created_at_from])
                                .created_until(params[:created_at_to])
                                .broadcasted_from(params[:broadcasted_at_from])
                                .broadcasted_until(params[:broadcasted_at_to])
                                .linked(params[:linked])
                                .order(created_at: :desc)
                                .paginate(page: params[:page], per_page: params[:per_page] || 25)
      end

      def pagination_data(items)
        return {} if items.blank?

        { total_entries: items.total_entries || 0, total_pages: items.total_pages || 0, current_page: items.current_page }
      end
    end
  end
end
