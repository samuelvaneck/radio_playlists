# frozen_string_literal: true

module Api
  module V1
    class SongsController < ApiController
      before_action :song, only: %i[show graph_data]

      def index
        render json: SongSerializer.new(songs)
                                   .serializable_hash
                                   .merge(pagination_data(songs))
                                   .to_json
      end

      def show
        render json: SongSerializer.new(song).serializable_hash.to_json
      end

      def graph_data
        render json: song.graph_data(params[:time] || params[:start_time])
      end

      def chart_positions
        render json: ChartPosition.item_positions_with_date(song)
      end

      private

      def songs
        @songs ||= Song.most_played(params).paginate(page: params[:page], per_page: 24)
      end

      def song
        @song ||= Song.find params[:id]
      end
    end
  end
end
