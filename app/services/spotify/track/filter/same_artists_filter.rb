module Spotify
  module Track
    module Filter
      class SameArtistsFilter < Base
        attr_reader :tracks

        def initialize(args)
          super
          @tracks = args[:tracks]
          @artists = args[:artists]
        end

        # filter out the tracks that don't have the same artists as the original search request artists
        def execute
          Array.wrap(@tracks)&.reject do |item|
            item_artist_names = item['album']['artists'].map { |artist| artist['name'] }
            different_artists = item_artist_names.join(', ') != @artists
            item['album']['album_type'] == 'compilation' && different_artists
          end
        end
      end
    end
  end
end
