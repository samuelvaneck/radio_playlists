# frozen_string_literal: true

module Api
  module V1
    class PlaylistsController < ApiController
      def index
        @playlists = playlists.paginate(page: params[:page], per_page: 24)
        render json: PlaylistSerializer.new(@playlists).serializable_hash.merge(pagination_data).to_json
      end

      private

      def playlists
        Playlist.includes([:song, :radio_station]).last_played(params)
      end

      def pagination_data
        return {} if @playlists.blank?

        { total_entries: @playlists.total_entries || 0, total_pages: @playlists.total_pages || 0, current_page: @playlists.current_page }
      end
    end
  end
end

