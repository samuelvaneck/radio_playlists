# frozen_string_literal: true
class TrackExtractor::SpotifyTrackFinder < TrackExtractor
  def find
    track = Spotify::Track::Finder.new(spotify_service_args)
    track.execute
    track
  end

  private

  def spotify_service_args
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
