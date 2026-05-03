# frozen_string_literal: true

module Tidal
  module ArtistFinder
    class Result < Base
      attr_reader :artist, :name, :id, :tidal_artist_url

      def initialize(args)
        super(artists: args[:name])
        @search_name = args[:name]
        @country = args[:country] || DEFAULT_COUNTRY
      end

      def execute
        @artist = find_best_match
        return nil if @artist.blank?

        @name = @artist.dig('attributes', 'name')
        @id = @artist['id']&.to_s
        @tidal_artist_url = @id.present? ? "https://tidal.com/browse/artist/#{@id}" : nil
        @artist
      end

      def valid_match?
        return false if @artist.blank?

        @artist['name_distance'].to_i >= ARTIST_SIMILARITY_THRESHOLD
      end

      private

      # Tidal's `/v2/searchResults/{query}?include=artists` returns artists in
      # search-ranking order via `data.relationships.artists.data`, while the
      # `included` array holds full artist resources without preserving order.
      # We walk the relationship list in rank order, resolve each from
      # `included`, score by name distance, and pick the first that passes the
      # threshold — preserving relevance over raw popularity.
      def find_best_match
        query = ERB::Util.url_encode(@search_name.to_s)
        url = "/v2/searchResults/#{query}?countryCode=#{@country}&include=artists"
        response = make_request(url)

        return nil if response.blank?

        ranked_ids = Array(response.dig('data', 'relationships', 'artists', 'data')).map { |r| r['id'] }
        return nil if ranked_ids.blank?

        included_by_id = Array(response['included']).select { |r| r['type'] == 'artists' }.index_by { |r| r['id'] }
        candidates = ranked_ids.filter_map { |id| included_by_id[id] }

        scored = candidates.map { |a| attach_name_score(a) }
        scored.find { |a| a['name_distance'].to_i >= ARTIST_SIMILARITY_THRESHOLD }
      end

      def attach_name_score(artist)
        artist['name_distance'] = artist_distance(artist.dig('attributes', 'name'))
        artist
      end
    end
  end
end
