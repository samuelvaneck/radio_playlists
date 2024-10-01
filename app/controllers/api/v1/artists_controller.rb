# frozen_string_literal: true

module Api
  module V1
    class ArtistsController < ApiController
      before_action :artist, only: %i[show graph_data songs]
      def index
        render json: ArtistSerializer.new(artists)
                                     .serializable_hash
                                     .merge(pagination_data(artists))
                                     .to_json
      end

      def show
        render json: ArtistSerializer.new(artist).serializable_hash.to_json
      end

      def graph_data
        render json: artist.graph_data(params[:time] || params[:start_time])
      end

      def songs
        render json: SongSerializer.new(artist.songs).serializable_hash.to_json
      end

      private

      def artists
        @artists ||= Artist.most_played(params).paginate(page: params[:page], per_page: 24)
      end

      def artist
        @artist ||= Artist.find params[:id]
      end
    end
  end
end

