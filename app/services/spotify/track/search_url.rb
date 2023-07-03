module Spotify
  module Track
    class SearchUrl < Base
      attr_reader :title, :artists, :spotify_url, :isrc

      FEATURING_REGEX = /\(feat\..+\)/.freeze

      def initialize(args)
        super
        @title = args[:title]
        @artists = args[:artists]
        @spotify_url = args[:spotify_url]
        @isrc =args[:isrc]
      end

      def generate
        URI("https://api.spotify.com/v1/search?q=#{search_params}&type=track")
      end

      private

      def search_params
        # return @spotify_url if @spotify_url.present?

        params = if title_has_featuring_artists?
                   "#{title_without_featuring_artists} track:#{title_without_featuring_artists} artist:#{split_artists_with_featuring_artists}"
                 else
                   "#{@title.downcase} track:#{@title.downcase} artist:#{split_artists}"
                 end
        params += " isrc:#{@isrc}" if @isrc.present?
        params.gsub(" ", "%20")
      end

      def split_artists
        regex = Regexp.new(ENV['MULTIPLE_ARTIST_REGEX'], Regexp::IGNORECASE)
        @artists.match?(regex) ? @artists.downcase.split(regex).map(&:strip).join(' ') : @artists.downcase
      end

      def split_artists_with_featuring_artists
        "#{split_artists} #{featuring_artists}".downcase
      end

      def featuring_artists
        return @title unless title_has_featuring_artists?

        regex = Regexp.new(FEATURING_REGEX)
        title.scan(regex).map { |i| i.split("(feat.")[1] }[0].strip.gsub(')', '').downcase
      end

      def title_has_featuring_artists?
        @title.match?(Regexp.new(FEATURING_REGEX))
      end

      def title_without_featuring_artists
        return @title unless title_has_featuring_artists?

        regex = Regexp.new(FEATURING_REGEX)
        title.split(regex)[0].strip.downcase
      end
    end
  end
end
