# frozen_string_literal: true

class TrackExtractor::ItunesTrackFinder < TrackExtractor
  def find
    return if played_song.blank?

    track = Itunes::TrackFinder::Result.new(itunes_service_args)
    track.execute
    track
  end

  private

  def itunes_service_args
    {
      artists: artist_name,
      title: title
    }
  end
end
