module Spotify
  module Track
    module Filter
      class SingleTracks
        attr_reader :tracks

        def initialize(args)
          @tracks = args[:tracks]
        end

        def filter
          return [] if @tracks.blank?

          dig_for_usable_tracks.select do |track|
            track.dig('album', 'album_type') == 'single'
          end
        end

        private

        def dig_for_usable_tracks
          ResultsDigger.new(tracks: @tracks).execute
        end
      end
    end
  end
end
