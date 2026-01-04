module Spotify
  module TrackFinder
    class Result < Base
      attr_reader :track, :artists, :title, :id, :isrc, :spotify_artwork_url,
                  :spotify_song_url, :spotify_query_result, :filter_result, :tracks,
                  :spotify_preview_url, :release_date, :release_date_precision,
                  :matched_artist_distance, :matched_title_distance

      TRACK_TYPES = %w[album single compilation].freeze
      FEATURING_REGEX = /\(feat\..+\)/

      def initialize(args)
        super
        @search_artists = args[:artists]
        @search_title = args[:title]
        @spotify_track_id = args[:spotify_track_id]
        @spotify_search_url = args[:spotify_search_url]
      end

      def execute
        @track = if args[:spotify_track_id]
                   fetch_spotify_track
                 else
                   best_match
                 end

        @artists = set_track_artists
        @title = set_track_title
        @isrc = set_isrc
        @spotify_song_url = set_spotify_song_url
        @spotify_artwork_url = set_spotify_artwork_url
        @spotify_preview_url = set_spotify_preview_url
        @matched_artist_distance = set_matched_artist_distance
        @matched_title_distance = set_matched_title_distance
        @id = set_id
        @release_date = set_release_date
        @release_date_precision = set_release_date_precision

        @track
      end

      def fetch_spotify_track
        @spotify_query_result = FindById.new(id_on_spotify: @spotify_track_id).execute

        # set the @filter_result
        dig_for_usable_tracks
        filter_same_artists

        if @filter_result.present?
          reject_custom_albums
          most_popular_track
        else
          @search_title = @spotify_query_result['name']
          @spotify_query_result = nil
          best_match
        end
      end

      def spotify_query_result
        @spotify_query_result ||= make_request_with_match(search_url)
      end

      # Returns a hash with the best matching score for each type
      # e.g. { 'album' => 124, 'single' => 269, 'compilation' => 75 }
      # The best matching scores are determined by the number of matching artists and the title distance.
      # Returns an empty hash if no matches are found.
      #
      # @return [Hash, nil]
      def match_score_results
        result = {}
        album_matches = Filter::AlbumTracks.new(tracks: spotify_query_result, artists: @search_artists).best_matching
        single_matches = Filter::SingleTracks.new(tracks: spotify_query_result, artists: @search_artists).best_matching
        compilation_matches = Filter::CompilationTracks.new(tracks: spotify_query_result, artists: @search_artists).best_matching

        result['album'] = album_matches if album_matches.present?
        result['single'] = single_matches if single_matches.present?
        result['compilation'] = compilation_matches if compilation_matches.present?

        result
      end

      # Returns the best matching track based on the match_score_results.
      # It uses the highest score from match_score_results to determine the type of track to filter
      # and then returns the best matching track from that type.
      #
      # @return [Spotify::TrackFinder, nil]
      def best_match
        @spotify_query_result ||= spotify_query_result
        type = match_score_results.key(match_score_results.values.max)
        return nil if type.blank?

        type_to_filter_class(type).new(tracks: spotify_query_result, artists: @search_artists).best_matching_track
      end

      private

      def search_url
        SearchUrl.new(title: @search_title,
                      artists: @search_artists,
                      spotify_url: @spotify_search_url).generate
      end

      # setter methods
      def set_track_artists
        return if @track.blank? || @track['album'].blank? || @track['album']['artists'].blank?

        album_artists = @track['album']['artists'].map { |artist| artist['name'] }
        artists = if title_has_featuring_artists? || album_artists.include?('Various Artists')
                    @track['artists']
                  else
                    @track['album']['artists']
                  end

        artists.map do |artist|
          Spotify::ArtistFinder.new({ id_on_spotify: artist['id'] }).info
        end
      end

      def set_track_title
        return if @track.blank?

        @track['name'] if @track.present?
      end

      def set_isrc
        return if @track.blank?

        @track.dig('external_ids', 'isrc')
      end

      def set_id
        return if @track.blank?

        @track['id']
      end

      def set_release_date
        return if @track.blank?

        if @track.dig('album', 'release_date_precision') != 'day'
          @track.dig('album', 'release_date')
        elsif @track.dig('album', 'release_date_precision') == 'month'
          "#{@track.dig('album', 'release_date')}-01"
        elsif @track.dig('album', 'release_date_precision') == 'year'
          "#{@track.dig('album', 'release_date')}-01-01"
        end
      end

      def set_release_date_precision
        return if @track.blank?

        @track.dig('album', 'release_date_precision')
      end

      def set_spotify_song_url
        return if @track.blank?

        @track.dig('external_urls', 'spotify')
      end

      def set_spotify_artwork_url
        return if @track.blank?

        @track.dig('album', 'images')[0]['url'] if track.dig('album', 'images').present?
      end

      def set_spotify_preview_url
        return if @track.blank?

        @track['preview_url']
      end

      def set_matched_artist_distance
        return if @track.blank?

        @track['artist_distance']
      end

      def set_matched_title_distance
        return if @track.blank?

        @track['title_distance']
      end

      def valid_match?
        return false if @track.blank?

        @matched_artist_distance.to_i >= ARTIST_SIMILARITY_THRESHOLD &&
          @matched_title_distance.to_i >= TITLE_SIMILARITY_THRESHOLD
      end

      def dig_for_usable_tracks
        @filter_result = Filter::ResultsDigger.new(tracks: @spotify_query_result).execute
      end

      def filter_same_artists
        @filter_result = Filter::SameArtistsFilter.new(tracks: @filter_result, artists: @search_artists).execute
      end

      def reject_custom_albums
        @tracks = Filter::CustomAlbumRejector.new(tracks: @filter_result).execute
      end

      def type_to_filter_class(type)
        "Spotify::TrackFinder::Filter::#{type.humanize}Tracks".constantize
      end

      def most_popular_track
        MostPopular.new(tracks: @tracks).execute
      end

      def title_has_featuring_artists?
        @search_title.match?(Regexp.new(FEATURING_REGEX))
      end
    end
  end
end
