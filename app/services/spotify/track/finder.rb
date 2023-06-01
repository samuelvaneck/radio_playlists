module Spotify
  module Track
    class Finder < Base
      attr_reader :track, :artists, :title, :isrc, :spotify_artwork_url, :spotify_song_url

      def initialize(args)
        super
        @search_artists = args[:artists]
        @search_title = args[:title]
        @track = if args[:spotify_track_id]
                   @spotify_track_id = args[:spotify_track_id]
                   fetch_spotify_track
                 else
                   search_spotify_track
                 end
        @artists = set_track_artists
        @title = set_track_title
        @isrc = set_isrc
        @spotify_song_url = set_spotify_song_url
        @spotify_artwork_url = set_spotify_artwork_url
      end

      def fetch_spotify_track
        result = Spotify::Track::FindById.new(@spotify_track_id).execute
        tracks = Spotify::Track::Filter.new(result, @search_artists).execute
        if tracks.present?
          filtered_tracks = custom_album_rejector(tracks)
          filtered_tracks.max_by { |track| track['popularity'] }
        else
          @search_title = result['name']
          search_spotify_track
        end
      end

      def search_spotify_track
        spotify_search_results = make_request(search_url)
        return if spotify_search_results.blank?

        tracks = Spotify::Track::Filter.new(spotify_search_results, @search_artists).execute
        if tracks.blank?
          @search_title = @args[:title]
          spotify_search_results = make_request(search_url)
          tracks = Spotify::Track::Filter.new(spotify_search_results, @search_artists).execute
        end
        return if tracks.blank?

        filtered_tracks = custom_album_rejector(tracks)
        filtered_tracks.max_by { |track| track['popularity'] }
      end

      private

      # make request params
      def search_url
        URI("https://api.spotify.com/v1/search?q=#{search_params}&type=track")
      end

      def search_params
        CGI.escape("#{@search_title} artist:#{split_artists}")
      end

      def split_artists
        regex = Regexp.new(ENV['MULTIPLE_ARTIST_REGEX'], Regexp::IGNORECASE)
        @search_artists.match?(regex) ? @search_artists.downcase.split(regex).map(&:strip).join(' ') : @search_artists.downcase
      end

      # setter methods
      def set_track_artists
        return if track.blank? || track['album'].blank? || track['album']['artists'].blank?

        track['album']['artists'].map do |artist|
          Spotify::Artist.new({ id_on_spotify: artist['id'] }).info
        end
      end

      def set_track_title
        return if track.blank?

        track['name'] if track.present?
      end

      def custom_album_rejector(single_album_tracks)
        track_filters = ENV['TRACK_FILTERS'].split(',')
        single_album_tracks.reject do |track|
          artist_names = track['album']['artists'].map { |artist| artist['name'] }.join.downcase.split
          (track_filters - artist_names).count < track_filters.count
        end
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
    end
  end
end
