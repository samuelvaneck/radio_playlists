module Spotify
  module TrackFinder
    class BestMatch < Base
      attr_reader :tracks

      def initialize(args)
        super
        @tracks = args[:tracks]
      end

      def execute
        @tracks.max_by { |track| track['match'] }
      end
    end
  end
end
