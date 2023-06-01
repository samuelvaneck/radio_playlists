module Spotify
  module Track
    class FindById < Base
      attr_reader :id_on_spotify

      SPOTIFY_TRACKS_URL = 'https://api.spotify.com/v1/tracks'.freeze

      def  initialize(id_on_spotify)
        @id_on_spotify = @id_on_spotify
      end

      def execute
        make_request(url)
      end

      private def url
        URI("#{SPOTIFY_TRACKS_URL}/#{@spotify_track_id}")
      end
    end
  end
end
