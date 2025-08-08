module Spotify
  module Track
    class SearchUrl < Base
      attr_reader :title, :artists, :spotify_url

      def initialize(args)
        super
        @title = args[:title]
        @artists = args[:artists]
        @spotify_url = args[:spotify_url]
      end

      def generate
        URI("https://api.spotify.com/v1/search?q=#{search_params}&type=track")
      end

      private

      def search_params
        return @spotify_url.gsub('spotify:search:', '') if @spotify_url.present?

        CGI.escape("#{@title} artist:#{split_artists}").gsub('+', '%20')
      end

      def split_artists
        regex = Regexp.new(Song::MULTIPLE_ARTIST_REGEX, Regexp::IGNORECASE)
        @artists.match?(regex) ? @artists.downcase.split(regex).map(&:strip).join(' ') : @artists.downcase
      end
    end
  end
end
