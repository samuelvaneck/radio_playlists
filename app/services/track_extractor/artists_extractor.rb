# frozen_string_literal: true

class TrackExtractor::ArtistsExtractor < TrackExtractor
  def extract
    find_or_create_artist
  end

  private

  def find_or_create_artist
    if @track.present? && @track.artists.present?
      Artist.spotify_track_to_artist(@track)
    else
      Artist.find_or_initialize_by(name: artist_name)
    end
  rescue StandardError => e
    Sentry.capture_exception(e)
    nil
  end
end
