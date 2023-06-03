module Spotify
  module Track
    class MostPopular < Base
      attr_reader :tracks

      def initialize(args)
        super
        @tracks = args[:tracks]
      end

      def execute
        @tracks.max_by { |track| track['popularity'] }
      end
    end
  end
end
