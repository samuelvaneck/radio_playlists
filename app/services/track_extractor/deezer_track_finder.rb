# frozen_string_literal: true

class TrackExtractor::DeezerTrackFinder < TrackExtractor
  def find
    return if played_song.blank?

    track = Deezer::TrackFinder::Result.new(deezer_service_args)
    track.execute
    track
  end

  private

  def deezer_service_args
    {
      artists: artist_name,
      title: title,
      isrc: isrc_code
    }
  end
end
