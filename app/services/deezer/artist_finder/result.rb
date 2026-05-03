# frozen_string_literal: true

module Deezer
  module ArtistFinder
    class Result < Base
      attr_reader :artist, :name, :id, :deezer_artist_url, :deezer_artwork_url

      def initialize(args)
        super(artists: args[:name])
        @search_name = args[:name]
      end

      def execute
        @artist = find_best_match
        return nil if @artist.blank?

        @name = @artist['name']
        @id = @artist['id']&.to_s
        @deezer_artist_url = @artist['link']
        @deezer_artwork_url = @artist['picture_xl'] || @artist['picture_big'] || @artist['picture']
        @artist
      end

      def valid_match?
        return false if @artist.blank?

        @artist['name_distance'].to_i >= ARTIST_SIMILARITY_THRESHOLD
      end

      private

      def find_best_match
        query = ERB::Util.url_encode(@search_name.to_s)
        url = "/search/artist?q=#{query}&limit=10"
        response = make_request(url)

        return nil if response.blank? || response['error'].present? || response['data'].blank?

        scored = response['data'].map { |artist| attach_name_score(artist) }
        scored.find { |a| a['name_distance'].to_i >= ARTIST_SIMILARITY_THRESHOLD }
      end

      def attach_name_score(artist)
        artist['name_distance'] = artist_distance(artist['name'])
        artist
      end
    end
  end
end
