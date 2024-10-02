module Spotify
  module Track
    class Finder < Base
      attr_reader :track, :artists, :title, :id, :isrc, :spotify_artwork_url,
                  :spotify_song_url, :query_result, :filter_result, :tracks,
                  :spotify_preview_url

      TRACK_TYPES = %w[album single compilation].freeze
      FEATURING_REGEX = /\(feat\..+\)/

      def initialize(args)
        super
        @search_artists = args[:artists]
        @search_title = args[:title]
        @spotify_track_id = args[:spotify_track_id]
        @spotify_search_url = args[:spotify_search_url]
        @search_isrc = args[:isrc_code]
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
        @title_distance = set_title_distance
        @id = set_id

        @track
      end

      def fetch_spotify_track
        @query_result = FindById.new(id_on_spotify: @spotify_track_id).execute

        # set the @filter_result
        dig_for_usable_tracks
        filter_same_artists

        if @filter_result.present?
          reject_custom_albums
          most_popular_track
        else
          @search_title = @query_result['name']
          @query_result = nil
          best_match
        end
      end

      def query_result
        @query_result ||= make_request_with_match(search_url)
      end

      def match_results
        result = {}
        TRACK_TYPES.each do |type|
          match = type_to_filter_class(type).new(tracks: @query_result, artists: @search_artists).best_matching
          next if match.nil?

          result[type] = match
        end
        result
      end

      def best_match
        @query_result ||= query_result
        type = match_results.key(match_results.values.max)
        return nil if type.blank?

        type_to_filter_class(type).new(tracks: @query_result, artists: @search_artists).best_matching_track
      end

      private

      def search_url
        SearchUrl.new(title: @search_title,
                      artists: @search_artists,
                      spotify_url: @spotify_search_url,
                      isrc: @search_isrc).generate
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

      def set_id
        return if @track.blank?

        @track['id']
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

      def set_title_distance
        return if @track.blank?

        @track['title_distance']
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

      def type_to_filter_class(type)
        "Spotify::Track::Filter::#{type.humanize}Tracks".constantize
      end

      def most_popular_track
        Spotify::Track::MostPopular.new(tracks: @tracks).execute
      end

      def title_has_featuring_artists?
        @search_title.match?(Regexp.new(FEATURING_REGEX))
      end
    end
  end
end
