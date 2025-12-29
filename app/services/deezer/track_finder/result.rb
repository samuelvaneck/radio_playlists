# frozen_string_literal: true

module Deezer
  module TrackFinder
    class Result < Base
      attr_reader :track, :artists, :title, :id, :isrc,
                  :deezer_artwork_url, :deezer_song_url, :deezer_preview_url,
                  :release_date

      MINIMUM_TITLE_SIMILARITY = 70

      def initialize(args)
        super
        @search_artists = args[:artists]
        @search_title = args[:title]
        @isrc_code = args[:isrc]
      end

      def execute
        @track = find_best_match
        return nil if @track.blank?

        @artists = set_artists
        @title = set_title
        @id = set_id
        @isrc = set_isrc
        @deezer_song_url = set_song_url
        @deezer_artwork_url = set_artwork_url
        @deezer_preview_url = set_preview_url
        @release_date = set_release_date

        @track
      end

      def valid_match?
        return false if @track.blank?

        @track['title_distance'].to_i >= MINIMUM_TITLE_SIMILARITY
      end

      private

      def find_best_match
        # Try ISRC first if available (most accurate)
        if @isrc_code.present?
          isrc_result = search_by_isrc
          return isrc_result if isrc_result.present? && isrc_result['title_distance'].to_i >= MINIMUM_TITLE_SIMILARITY
        end

        # Fall back to artist/title search
        search_by_query
      end

      def search_by_isrc
        url = "/2.0/track/isrc:#{@isrc_code}"
        response = make_request(url)

        return nil if response.blank? || response['error'].present?

        add_match_score(response)
      end

      def search_by_query
        query = ERB::Util.url_encode("artist:\"#{@search_artists}\" track:\"#{@search_title}\"")
        url = "/search?q=#{query}&limit=25"
        response = make_request(url)

        return nil if response.blank? || response['data'].blank?

        tracks = response['data']
        tracks_with_scores = tracks.map { |track| add_match_score(track) }.compact

        # Select best match by title_distance that meets threshold
        valid_tracks = tracks_with_scores.select { |t| t['title_distance'].to_i >= MINIMUM_TITLE_SIMILARITY }
        valid_tracks.max_by { |t| t['title_distance'] }
      end

      def add_match_score(track)
        return nil if track.blank?

        artist_name = track.dig('artist', 'name') || ''
        track_name = track['title'] || ''

        distance = string_distance("#{artist_name} #{track_name}")
        track['title_distance'] = distance
        track
      end

      def set_artists
        return nil if @track.blank? || @track['artist'].blank?

        [{ 'name' => @track.dig('artist', 'name'), 'id' => @track.dig('artist', 'id') }]
      end

      def set_title
        @track&.dig('title')
      end

      def set_id
        @track&.dig('id')&.to_s
      end

      def set_isrc
        @track&.dig('isrc')
      end

      def set_song_url
        @track&.dig('link')
      end

      def set_artwork_url
        # Deezer provides different sizes: cover, cover_small, cover_medium, cover_big, cover_xl
        @track&.dig('album', 'cover_big') || @track&.dig('album', 'cover')
      end

      def set_preview_url
        @track&.dig('preview')
      end

      def set_release_date
        @track&.dig('album', 'release_date')
      end
    end
  end
end
