# frozen_string_literal: tru

class Spotify
  attr_accessor :artists, :title

  MULTIPLE_ARTIST_REGEX = ';|\bfeat\.|\bvs\.|\bft\.|\bft\b|\bfeat\b|\bft\b|&|\bvs\b|\bversus|\band\b|\bmet\b|\b,|\ben\b|\/'.freeze
  TRACK_FILTERS = ['karaoke', 'cover', 'made famous', 'tribute', 'backing business', 'arcade', 'instrumental', '8-bit', '16-bit'].freeze
  private_constant :MULTIPLE_ARTIST_REGEX
  private_constant :TRACK_FILTERS

  def initialize(artists: nil, title: nil)
    @artists = artists
    @title = title
  end

  def find_spotify_track
    search_term = split_artists
    spotify_search_results = spotify_search(search_term)
    single_album_tracks = filter_single_and_album_tracks(spotify_search_results)
    filtered_tracks = custom_album_rejector(single_album_tracks)
    filtered_tracks.max_by(&:popularity)
  end

  private

  def split_artists
    regex = Regexp.new(MULTIPLE_ARTIST_REGEX, Regexp::IGNORECASE)
    @artists.match?(regex) ? @artists.downcase.split(regex).map(&:strip).join(' ') : @artists.downcase
  end

  def spotify_search(search_term)
    RSpotify::Track.search("#{search_term} #{@title}")
                   .sort_by(&:popularity)
                   .reverse
  end

  def filter_single_and_album_tracks(spotify_tracks_search)
    spotify_tracks_search.reject { |t| t.album.album_type == 'compilation' }
  end

  def custom_album_rejector(single_album_tracks)
    single_album_tracks.reject { |t| (TRACK_FILTERS - t.artists.map(&:name).join.downcase.split).count < TRACK_FILTERS.count }
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
