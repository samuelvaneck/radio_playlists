module Spotify
  module Track
    class Finder < Base
      attr_reader :track, :artists, :title, :isrc, :spotify_artwork_url, :spotify_song_url, :query_result, :filter_result, :tracks

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
                   search_spotify_track
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
          search_spotify_track
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

      private

      def search_url
        SearchUrl.new(title: @search_title, artists: @search_artists).execute
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


      def single_over_albums(single_album_tracks)
        single_tracks(single_album_tracks) || album_tracks(single_album_tracks)
      end

      def single_tracks(single_album_tracks)
        single_album_tracks.select { |t| t.album.album_type == 'single' }
      end

      def album_tracks(single_album_tracks)
        single_album_tracks.select { |t| t.album.album_type == 'album' }
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
