module Spotify
  module TrackFinder
    class FindById < Base
      attr_reader :id_on_spotify

      SPOTIFY_TRACKS_URL = 'https://api.spotify.com/v1/tracks'.freeze

      def  initialize(args)
        super
        @id_on_spotify = args[:id_on_spotify]
      end

      def execute
        make_request(url)
      end

      private def url
        URI("#{SPOTIFY_TRACKS_URL}/#{@id_on_spotify}")
      end
    end
  end
end
