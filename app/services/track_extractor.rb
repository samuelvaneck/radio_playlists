# frozen_string_literal: true

class TrackExtractor
  def initialize(played_song:, track: nil, artists: nil)
    @played_song = played_song
    @track = track
    @artists = artists
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
end
