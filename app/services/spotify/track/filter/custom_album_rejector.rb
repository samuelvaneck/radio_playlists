module Spotify
  module Track
    module Filter
      class CustomAlbumRejector < Base
        attr_reader :tracks

        def initialize(args)
          super
          @tracks = args[:tracks]
        end

        def execute
          artists_filters = ENV['ARTISTS_FILTERS'].split(',')

          Array.wrap(@tracks).reject do |track|
            artist_names = track['album']['artists'].map { |artist| artist['name'] }.join.downcase.split
            (artists_filters - artist_names).count < artists_filters.count
          end
        end
      end
    end
  end
end
