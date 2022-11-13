# frozen_string_literal: true

# require Rails.root.join('app/services/spotify.rb')

class Spotify::Track < Spotify
  attr_reader :search_artists, :search_title, :track, :artists, :title

  def initialize(args)
    super()
    @track = if args[:spotify_track_id]
               @spotify_track_id = args[:spotify_track_id]
               fetch_spotify_track
             else
               @search_artists = args[:artists]
               @search_title = args[:title]
               search_spotify_track
             end
    @artists = set_track_artists
    @title = set_track_title
  end

  def fetch_spotify_track
    make_request(spotify_track_url)
  end

  def search_spotify_track
    spotify_search_results = make_request(search_url)
    return if spotify_search_results.blank?

    single_album_tracks = filter_single_and_album_tracks(spotify_search_results)
    filtered_tracks = custom_album_rejector(single_album_tracks)
    @track = filtered_tracks.max_by { |track| track['popularity'] }
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
    CGI.escape("#{@search_title} artist:#{split_artists}")
  end

  def split_artists
    regex = Regexp.new(ENV['MULTIPLE_ARTIST_REGEX'], Regexp::IGNORECASE)
    @search_artists.match?(regex) ? @search_artists.downcase.split(regex).map(&:strip).join(' ') : @search_artists.downcase
  end

  # setter methods
  def set_track_artists
    return if @track.blank?

    @track['album']['artists'].map do |artist|
      Spotify::Artist.new({ id_on_spotify: artist['id'] }).info
    end
  end

  def set_track_title
    @track['name'] if @track.present?
  end

  # filter methods
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
end
