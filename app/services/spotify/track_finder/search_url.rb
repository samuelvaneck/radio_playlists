module Spotify
  module TrackFinder
    class SearchUrl < Base
      attr_reader :title, :artists, :spotify_url

      def initialize(args)
        super
        @title = args[:title]
        @artists = args[:artists]
        @spotify_url = args[:spotify_url]
      end

      def generate(plain: false)
        URI("https://api.spotify.com/v1/search?q=#{search_params(plain:)}&type=track")
      end

      private

      # When `plain` is true, drop the `artist:` field filter and emit a plain
      # `artist title` query. The field filter is strict and suppresses fuzzy
      # spacing variants (e.g., scraped "Zo Maar" vs canonical "Zomaar"); the
      # plain form lets Spotify's tokenizer recover the canonical track.
      def search_params(plain: false)
        return @spotify_url.gsub('spotify:search:', '') if @spotify_url.present?

        query = plain ? "#{split_artists} #{@title}" : "#{@title} artist:#{split_artists}"
        CGI.escape(query).gsub('+', '%20')
      end

      def split_artists
        regex = Regexp.new(Song::MULTIPLE_ARTIST_REGEX, Regexp::IGNORECASE)
        @artists.match?(regex) ? @artists.downcase.split(regex).map(&:strip).join(' ') : @artists.downcase
      end
    end
  end
end
