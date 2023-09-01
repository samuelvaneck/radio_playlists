# frozen_string_literal: true

class TrackExtractor
  attr_reader :played_song

  def initialize(played_song:, track: nil, artists: nil)
    @played_song = played_song
    @track = track
    @artists = artists
  end

  private

  def title
    return if played_song.blank?

    @title ||= played_song.title
  end

  def artist_name
    return if played_song.blank?

    @artist_name ||= played_song.artist_name
  end

  def spotify_url
    return if played_song.blank?

    @spotify_url ||= played_song.spotify_url
  end

  def isrc_code
    return if played_song.blank?

    @isrc_code ||= played_song.isrc_code
  end
end
