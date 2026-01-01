# frozen_string_literal: true

module Itunes
  module TrackFinder
    class Result < Base
      attr_reader :track, :artists, :title, :id, :isrc,
                  :itunes_artwork_url, :itunes_song_url, :itunes_preview_url,
                  :release_date

      def initialize(args)
        super
        @search_artists = args[:artists]
        @search_title = args[:title]
        @country = args[:country] || DEFAULT_COUNTRY
      end

      def execute
        @track = find_best_match
        return nil if @track.blank?

        @artists = set_artists
        @title = set_title
        @id = set_id
        @isrc = set_isrc
        @itunes_song_url = set_song_url
        @itunes_artwork_url = set_artwork_url
        @itunes_preview_url = set_preview_url
        @release_date = set_release_date

        @track
      end

      def valid_match?
        return false if @track.blank?

        @track['artist_distance'].to_i >= ARTIST_SIMILARITY_THRESHOLD &&
          @track['title_distance'].to_i >= TITLE_SIMILARITY_THRESHOLD
      end

      private

      def find_best_match
        search_by_query
      end

      def search_by_query
        # iTunes Search API: combine artist and title for better results
        term = ERB::Util.url_encode("#{@search_artists} #{@search_title}")
        url = "/search?term=#{term}&media=music&entity=song&country=#{@country}&limit=25"
        response = make_request(url)

        return nil if response.blank? || response['results'].blank?

        tracks = response['results']
        tracks_with_scores = tracks.map { |track| add_match_score(track) }.compact

        # Select best match where both artist and title meet their thresholds
        valid_tracks = tracks_with_scores.select do |t|
          t['artist_distance'].to_i >= ARTIST_SIMILARITY_THRESHOLD &&
            t['title_distance'].to_i >= TITLE_SIMILARITY_THRESHOLD
        end
        # Use minimum of artist and title distance to rank matches
        valid_tracks.max_by { |t| [t['artist_distance'], t['title_distance']].min }
      end

      def add_match_score(track)
        return nil if track.blank?

        artist_name = track['artistName'] || ''
        track_name = track['trackName'] || ''

        track['artist_distance'] = artist_distance(artist_name)
        track['title_distance'] = title_distance(track_name)
        track
      end

      def set_artists
        return nil if @track.blank? || @track['artistName'].blank?

        [{ 'name' => @track['artistName'], 'id' => @track['artistId']&.to_s }]
      end

      def set_title
        @track&.dig('trackName')
      end

      def set_id
        @track&.dig('trackId')&.to_s
      end

      def set_isrc
        # iTunes doesn't directly provide ISRC in search results
        nil
      end

      def set_song_url
        @track&.dig('trackViewUrl')
      end

      def set_artwork_url
        # iTunes provides artworkUrl100, we can modify to get larger size
        artwork = @track&.dig('artworkUrl100')
        # Replace 100x100 with 600x600 for higher resolution
        artwork&.gsub('100x100', '600x600')
      end

      def set_preview_url
        @track&.dig('previewUrl')
      end

      def set_release_date
        @track&.dig('releaseDate')&.to_date&.to_s
      rescue ArgumentError
        nil
      end
    end
  end
end
