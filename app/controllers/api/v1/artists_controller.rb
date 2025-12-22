# frozen_string_literal: true

module Api
  module V1
    class ArtistsController < ApiController
      before_action :artist, only: %i[show graph_data songs chart_positions bio]
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

      def chart_positions
        artist.update_chart_positions if artist.update_cached_positions?

        render json: artist.reload.cached_chart_positions.presence || []
      end

      def bio
        artist_info = Lastfm::ArtistFinder.new.get_info(artist.name)

        if artist_info && artist_info[:bio]
          render json: { bio: artist_info[:bio] }
        else
          render json: { bio: nil }
        end
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
