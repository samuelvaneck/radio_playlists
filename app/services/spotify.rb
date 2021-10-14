# frozen_string_literal: tru

class Spotify
  attr_accessor :artists, :title, :track, :track_artists, :track_title

  class TokenCreationError < StandardError; end

  def initialize(artists: nil, title: nil)
    @artists = artists
    @title = title
    @token = get_token(cache: true)
    @track = find_spotify_track
    @track_artists = set_track_artists
    @track_title = set_track_title
  end

  def find_spotify_track
    url = search_url
    spotify_search_results = make_request(url)
    return if spotify_search_results.blank?

    single_album_tracks = filter_single_and_album_tracks(spotify_search_results)
    filtered_tracks = custom_album_rejector(single_album_tracks)
    filtered_tracks.max_by { |track| track['popularity'] }
  end

  private

  def filter_single_and_album_tracks(spotify_tracks_search)
    spotify_tracks_search['tracks']['items'].reject { |item| item['album']['album_type'] == 'compilation' }
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

  def get_token(cache: true)
    if cache
      Rails.cache.fetch(token_cache_key, expires_in: 1.hour) { create_token }
    else
      Rails.cache.write(token_cache_key, token = create_token, expires_in: 1.hour)
      token
    end
  rescue Errno::EACCES => e
    Sentry.capture_exception(e)
    get_token(cache: false)
  end

  def create_token
    https = Net::HTTP.new(token_url.host, token_url.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(token_url)
    request['Authorization'] = "Basic #{auth_str_base64}"
    request['Content-Type'] = 'application/x-www-form-urlencoded'
    request.body = 'grant_type=client_credentials'

    response = https.request(request)
    JSON(response.body)['access_token']
  end

  def token_cache_key
    [:spotify_token]
  end

  def token_url
    URI('https://accounts.spotify.com/api/token')
  end

  def auth_str_base64
    Base64.strict_encode64("#{ENV['SPOTIFY_CLIENT_ID']}:#{ENV['SPOTIFY_CLIENT_SECRET']}")
  end

  def make_request(url, method: 'GET', read_timeout: 60)
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Get.new(url)
    request['Authorization'] = "Bearer #{@token}"
    request['Content-Type'] = 'application/json'

    JSON(https.request(request).body)
  end

  def search_url
    URI("https://api.spotify.com/v1/search?q=#{search_params}&type=track")
  end

  def search_params
    CGI.escape("#{split_artists} #{@title}")
  end

  def split_artists
    regex = Regexp.new(ENV['MULTIPLE_ARTIST_REGEX'], Regexp::IGNORECASE)
    @artists.match?(regex) ? @artists.downcase.split(regex).map(&:strip).join(' ') : @artists.downcase
  end

  def artist_url(id_on_spotify)
    URI("https://api.spotify.com/v1/artists/#{id_on_spotify}")
  end

  def set_track_artists
    return if @track.blank?

    @track['album']['artists'].map do |artist|
      url = artist_url(artist['id'])
      make_request(url)
    end
  end

  def set_track_title
    @track['name'] if @track.present?
  end
end
