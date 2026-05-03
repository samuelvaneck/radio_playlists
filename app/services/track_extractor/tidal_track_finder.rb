# frozen_string_literal: true

class TrackExtractor::TidalTrackFinder < TrackExtractor
  def find
    return if played_song.blank?

    track = Tidal::TrackFinder::Result.new(tidal_service_args)
    track.execute
    track
  end

  private

  def tidal_service_args
    {
      artists: artist_name,
      title: title,
      isrc: isrc_code
    }
  end
end
