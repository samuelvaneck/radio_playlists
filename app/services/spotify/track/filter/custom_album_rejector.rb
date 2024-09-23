module Spotify
  module Track
    module Filter
      class CustomAlbumRejector < Base
        attr_reader :tracks

        ARTISTS_FILTERS = %w[karaoke cover made famous tribute backing business arcade instrumental 8-bit 16-bit].freeze

        def initialize(args)
          super
          @tracks = args[:tracks]
        end

        def execute
          Array.wrap(@tracks).reject do |track|
            artist_names = track['album']['artists'].map { |artist| artist['name'] }.join.downcase.split
            (ARTISTS_FILTERS - artist_names).count < ARTISTS_FILTERS.count
          end
        end
      end
    end
  end
end
