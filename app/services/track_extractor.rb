# frozen_string_literal: true

class TrackExtractor
  def initialize(played_song: played_song, artists: nil)
    @played_song = played_song
    @artists = artists
  end

  def spotify_track
    args = spotify_service_args(artist_name, title, spotify_url, isrc_code)
    track = Spotify::Track::Finder.new(args)
    track.execute
  end

  private

  def title
    @title ||= @played_song.title
  end

  def artist_name
    @artist_name ||= @played_song.artist_name
  end

  def spotify_url
    @spotify_url ||= @played_song.spotify_url
  end

  def isrc_code
    @isrc_code ||= @played_song.isrc_code
  end

  def spotify_service_args(artist_name, title, spotify_url = nil, isrc_code = nil)
    args = { artists: artist_name, title: }
    if spotify_url&.start_with?('spotify:search')
      args[:spotify_search_url] = spotify_url
    elsif spotify_url
      args[:spotify_track_id] = spotify_url.split('/').last
    end
    args[:isrc_code] = isrc_code if isrc_code.present?
    args
  end
end
