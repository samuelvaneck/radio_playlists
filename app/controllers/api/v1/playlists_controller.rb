# frozen_string_literal: true

module Api
  module V1
    class PlaylistsController < ApiController
      def index
        render json: PlaylistSerializer.new(playlists)
                                       .serializable_hash
                                       .merge(pagination_data(playlists))
                                       .to_json
      end

      private

      def playlists
        @playlists ||= Playlist.includes([:song, :radio_station])
                               .last_played(params)
                               .paginate(page: params[:page], per_page: 24)
      end
    end
  end
end

