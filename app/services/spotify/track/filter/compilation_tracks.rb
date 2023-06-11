module Spotify
  module Track
    module Filter
      class CompilationTracks
        attr_reader :tracks

        def initialize(args)
          @tracks = args[:tracks]
        end

        def same_artists_filter
          SameArtistsFilter.new(tracks: filter).execute
        end

        def most_popular
          MostPopular.new(tracks: same_artists_filter).execute
        end

        def most_popular_track
          @tracks = filter
          MostPopular.new(tracks: @tracks).execute
        end

        def best_matching
          best_matching_track&.dig('match')
        end

        def best_matching_track
          @tracks = filter
          BestMatch.new(tracks: @tracks).execute
        end

        private

        def filter
          return [] if @tracks.blank?

          dig_for_usable_tracks.select do |track|
            track.dig('album', 'album_type') == 'compilation'
          end
        end

        def dig_for_usable_tracks
          ResultsDigger.new(tracks: @tracks).execute
        end
      end
    end
  end
end
