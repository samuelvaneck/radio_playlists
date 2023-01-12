# frozen_string_literal: true

class Spotify::Track < Spotify
  attr_reader :track, :artists, :title, :isrc, :spotify_artwork_url, :spotify_song_url

  def initialize(args)
    super()
    @args = args
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
    result = make_request(spotify_track_url)
    tracks = filter_tracks(result)
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

    tracks = filter_tracks(spotify_search_results)
    if tracks.blank?
      @search_title = @args[:title]
      spotify_search_results = make_request(search_url)
      tracks = filter_tracks(spotify_search_results)
    end

    filtered_tracks = custom_album_rejector(tracks)
    filtered_tracks.max_by { |track| track['popularity'] }
  end

  private

  def spotify_track_url
    URI("https://api.spotify.com/v1/tracks/#{@spotify_track_id}")
  end

  # make request params
  def search_url
    URI("https://api.spotify.com/v1/search?q=#{search_params}&type=track")
  end

  def search_params
    if @args[:isrc_code]
      "isrc:#{@args[:isrc_code]}"
    elsif @args[:spotify_search_url]
      @args[:spotify_search_url].split('spotify:search:').last
    else
      CGI.scape("#{@search_title} artist:#{split_artists}")
    end
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

  # filter methods
  def filter_tracks(spotify_tracks_search)
    tracks = if spotify_tracks_search.dig('tracks', 'items').present?
               spotify_tracks_search['tracks']['items']
             elsif spotify_tracks_search.dig('album', 'album_type').present?
               spotify_tracks_search
             end

    Array.wrap(tracks)&.reject do |item|
      item_artist_names = item['artists'].map { |artist| artist['name'] }
      different_artists = item_artist_names.join(', ') != @args[:artists]
      item['album']['album_type'] == 'compilation' && different_artists
    end
  end

  def custom_album_rejector(single_album_tracks)
    track_filters = ENV['TRACK_FILTERS'].split(',')
    single_album_tracks.reject do |t|
      artist_names = t['artists'].map { |artist| artist['name'] }
                                 .join.downcase.split
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
