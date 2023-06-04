module Spotify
  module Track
    module Filter
      class CompilationTracks
        attr_reader :tracks

        def initialize(args)
          @tracks = args[:tracks]
        end

        def filter
          return [] if @tracks.blank?

          dig_for_usable_tracks.select do |track|
            track.dig('album', 'album_type') == 'compilation'
          end
        end

        def same_artists_filter
          SameArtistsFilter.new(tracks: filter).execute
        end

        def most_popular
          MostPopular.new(tracks: same_artists_filter).execute
        end

        private

        def dig_for_usable_tracks
          ResultsDigger.new(tracks: @tracks).execute
        end
      end
    end
  end
end
