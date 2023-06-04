module Spotify
  module Track
    class SearchUrl < Base
      attr_reader :title, :artists
      def initialize(args)
        super
        @title = args[:title]
        @artists = args[:artists]
      end

      def generate
        URI("https://api.spotify.com/v1/search?q=#{search_params}&type=track")
      end

      private

      def search_params
        CGI.escape("#{@title} artist:#{split_artists}")
      end

      def split_artists
        regex = Regexp.new(ENV['MULTIPLE_ARTIST_REGEX'], Regexp::IGNORECASE)
        @artists.match?(regex) ? @artists.downcase.split(regex).map(&:strip).join(' ') : @artists.downcase
      end
    end
  end
end
