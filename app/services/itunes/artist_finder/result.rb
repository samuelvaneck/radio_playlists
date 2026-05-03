# frozen_string_literal: true

module Itunes
  module ArtistFinder
    class Result < Base
      attr_reader :artist, :name, :id, :itunes_artist_url

      def initialize(args)
        super(artists: args[:name])
        @search_name = args[:name]
        @country = args[:country] || DEFAULT_COUNTRY
      end

      def execute
        @artist = find_best_match
        return nil if @artist.blank?

        @name = @artist['artistName']
        @id = @artist['artistId']&.to_s
        @itunes_artist_url = @artist['artistLinkUrl']
        @artist
      end

      def valid_match?
        return false if @artist.blank?

        @artist['name_distance'].to_i >= ARTIST_SIMILARITY_THRESHOLD
      end

      private

      def find_best_match
        term = ERB::Util.url_encode(@search_name.to_s)
        url = "/search?term=#{term}&entity=musicArtist&country=#{@country}&limit=10"
        response = make_request(url)

        return nil if response.blank? || response['results'].blank?

        scored = response['results'].map { |artist| attach_name_score(artist) }
        scored.find { |a| a['name_distance'].to_i >= ARTIST_SIMILARITY_THRESHOLD }
      end

      def attach_name_score(artist)
        artist['name_distance'] = artist_distance(artist['artistName'])
        artist
      end
    end
  end
end
