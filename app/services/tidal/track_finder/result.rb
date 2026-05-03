# frozen_string_literal: true

module Tidal
  module TrackFinder
    class Result < Base
      attr_reader :track, :artists, :title, :id, :isrc,
                  :tidal_artwork_url, :tidal_song_url,
                  :duration_ms

      def initialize(args)
        super
        @search_artists = args[:artists]
        @search_title = args[:title]
        @isrc_code = args[:isrc]
        @country = args[:country] || DEFAULT_COUNTRY
      end

      def execute
        @track = find_best_match
        return nil if @track.blank?

        @artists = set_artists
        @title = set_title
        @id = set_id
        @isrc = set_isrc
        @tidal_song_url = set_song_url
        @tidal_artwork_url = set_artwork_url
        @duration_ms = set_duration_ms

        @track
      end

      def valid_match?
        return false if @track.blank?

        @track['artist_distance'].to_i >= ARTIST_SIMILARITY_THRESHOLD &&
          @track['title_distance'].to_i >= TITLE_SIMILARITY_THRESHOLD
      end

      private

      def find_best_match
        if @isrc_code.present?
          isrc_result = search_by_isrc
          if isrc_result.present? &&
             isrc_result['artist_distance'].to_i >= ARTIST_SIMILARITY_THRESHOLD &&
             isrc_result['title_distance'].to_i >= TITLE_SIMILARITY_THRESHOLD
            return isrc_result
          end
        end

        search_by_query
      end

      def search_by_isrc
        url = "/v2/tracks?countryCode=#{@country}&filter%5Bisrc%5D=#{ERB::Util.url_encode(@isrc_code)}&include=artists,albums"
        response = make_request(url)

        return nil if response.blank? || response['data'].blank?

        included = Array(response['included'])
        track = Array(response['data']).first
        add_match_score(track, included)
      end

      def search_by_query
        query = ERB::Util.url_encode("#{@search_artists} #{@search_title}")
        url = "/v2/searchresults/#{query}?countryCode=#{@country}&include=tracks,artists,albums"
        response = make_request(url)

        return nil if response.blank?

        included = Array(response['included'])
        track_resources = included.select { |r| r['type'] == 'tracks' }
        return nil if track_resources.blank?

        scored = track_resources.filter_map { |t| add_match_score(t, included) }
        valid = scored.select do |t|
          t['artist_distance'].to_i >= ARTIST_SIMILARITY_THRESHOLD &&
            t['title_distance'].to_i >= TITLE_SIMILARITY_THRESHOLD
        end
        valid.max_by { |t| [t['artist_distance'], t['title_distance']].min }
      end

      def add_match_score(track, included)
        return nil if track.blank?

        track['artist_resources'] = artist_resources_for(track, included)
        track['album_resource'] = album_resource_for(track, included)

        track['artist_distance'] = artist_distance(combined_artist_name(track))
        track['title_distance'] = title_distance(track.dig('attributes', 'title'))
        track
      end

      def artist_resources_for(track, included)
        ids = Array(track.dig('relationships', 'artists', 'data')).pluck('id')
        return [] if ids.blank?

        included.select { |r| r['type'] == 'artists' && ids.include?(r['id']) }
      end

      def album_resource_for(track, included)
        album_id = track.dig('relationships', 'albums', 'data')&.first&.dig('id')
        return nil if album_id.blank?

        included.find { |r| r['type'] == 'albums' && r['id'] == album_id }
      end

      def combined_artist_name(track)
        names = Array(track['artist_resources']).filter_map { |a| a.dig('attributes', 'name') }
        names.join(' & ')
      end

      def set_artists
        Array(@track&.dig('artist_resources')).map do |resource|
          { 'name' => resource.dig('attributes', 'name'), 'id' => resource['id'] }
        end
      end

      def set_title
        @track&.dig('attributes', 'title')
      end

      def set_id
        @track&.dig('id')&.to_s
      end

      def set_isrc
        @track&.dig('attributes', 'isrc')
      end

      def set_song_url
        return nil if @id.blank?

        "https://tidal.com/browse/track/#{@id}"
      end

      def set_artwork_url
        image_links = @track&.dig('album_resource', 'attributes', 'imageLinks') || []
        largest = image_links.max_by { |link| link.dig('meta', 'width').to_i }
        largest&.dig('href')
      end

      def set_duration_ms
        iso = @track&.dig('attributes', 'duration')
        return nil if iso.blank?

        ActiveSupport::Duration.parse(iso).to_i * 1000
      rescue ActiveSupport::Duration::ISO8601Parser::ParsingError
        nil
      end
    end
  end
end
