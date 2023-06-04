module Spotify
  module Track
    class Finder < Base
      attr_reader :track, :artists, :title, :isrc, :spotify_artwork_url, :spotify_song_url, :query_result, :filter_result, :tracks
      POPULARITY_TYPES = %w[album single compilation].freeze

      def initialize(args)
        super
        @search_artists = args[:artists]
        @search_title = args[:title]
        @spotify_track_id = args[:spotify_track_id]
      end

      def execute
        @track = if args[:spotify_track_id]
                   fetch_spotify_track
                 else
                   # search_spotify_track
                   best_result
                 end
        @artists = set_track_artists
        @title = set_track_title
        @isrc = set_isrc
        @spotify_song_url = set_spotify_song_url
        @spotify_artwork_url = set_spotify_artwork_url

        @track
      end

      def fetch_spotify_track
        @query_result = FindById.new(@spotify_track_id).execute

        # set the @filter_result
        dig_for_usable_tracks
        filter_same_artists

        if @filter_result.present?
          reject_custom_albums
          most_popular_track
        else
          @search_title = result['name']
          @query_result = nil
          # search_spotify_track
          best_result
        end
      end

      def search_spotify_track
        @query_result = make_request(search_url)
        return if @query_result.blank?

        # sets @filter_result
        dig_for_usable_tracks
        filter_same_artists
        if @filter_result.blank?
          @search_title = @args[:title]
          @query_result = make_request(search_url)

          # sets @filter_result
          dig_for_usable_tracks
          filter_same_artists
        end
        return if @filter_result.blank?

        reject_custom_albums
        most_popular_track
      end

      def album_tracks
        @query_result ||= make_request(search_url)
        Filter::AlbumTracks.new(tracks: @query_result).filter
      end

      def most_popular_album_track
        @tracks = album_tracks
        most_popular_track
      end

      def most_popular_album_track_link
        most_popular_album_track&.dig('external_urls', 'spotify')
      end

      def most_popular_album_track_popularity
        most_popular_album_track&.dig('popularity')
      end

      def single_tracks
        @query_result ||= make_request(search_url)
        Filter::SingleTracks.new(tracks: @query_result).filter
      end

      def most_popular_single_track
        @tracks = single_tracks
        most_popular_track
      end

      def most_popular_single_track_link
        most_popular_single_track&.dig('external_urls', 'spotify')
      end

      def most_popular_single_track_popularity
        most_popular_single_track&.dig('popularity')
      end

      def compilation_tracks
        @query_result ||= make_request(search_url)
        Filter::CompilationTracks.new(tracks: @filter_result).filter
      end

      def most_popular_compilation_track
        @tracks = compilation_tracks
        most_popular_track
      end

      def most_popular_compilation_track_link
        most_popular_compilation_track&.dig('external_urls', 'spotify')
      end

      def most_popular_compilation_track_popularity
        most_popular_compilation_track&.dig('popularity')
      end

      def popularity_results
        result = {}
        POPULARITY_TYPES.each do |type|
          popularity = send("most_popular_#{type}_track_popularity".to_sym)
          next if popularity.nil?

          result[type] = popularity
        end

        result
      end

      def best_result
        result = popularity_results.key(popularity_results.values.max)

        send("most_popular_#{result}_track".to_sym)
      end

      # test purpose
      def request_results_with_string_match
        make_request_with_sting_match(search_url)
      end

      private

      def search_url
        SearchUrl.new(title: @search_title, artists: @search_artists).generate
      end

      # setter methods
      def set_track_artists
        return if @track.blank? || @track['album'].blank? || @track['album']['artists'].blank?

        @track['album']['artists'].map do |artist|
          Spotify::Artist.new({ id_on_spotify: artist['id'] }).info
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

      def set_spotify_song_url
        return if @track.blank?

        @track.dig('external_urls', 'spotify')
      end

      def set_spotify_artwork_url
        return if @track.blank?

        @track.dig('album', 'images')[0]['url'] if track.dig('album', 'images').present?
      end

      def most_popular_track
        MostPopular.new(tracks: @tracks).execute
      end

      def dig_for_usable_tracks
        @filter_result = Spotify::Track::Filter::ResultsDigger.new(tracks: @query_result).execute
      end

      def filter_same_artists
        @filter_result = Spotify::Track::Filter::SameArtistsFilter.new(tracks: @filter_result, artists: @search_artists).execute
      end

      def reject_custom_albums
        @tracks = Spotify::Track::Filter::CustomAlbumRejector.new(tracks: @filter_result).execute
      end
    end
  end
end
