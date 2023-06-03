module Spotify
  module Track
    module Filter
      class ResultsDigger < Base
        attr_reader :tracks

        def initialize(args)
          super
          @tracks = args[:tracks]
        end

        # return the correct search results for different spotify requests
        def execute
          if @tracks.dig('tracks', 'items').present?
            @tracks['tracks']['items']
          elsif @tracks.dig('album', 'album_type').present?
            @tracks
          end
        end
      end
    end
  end
end
