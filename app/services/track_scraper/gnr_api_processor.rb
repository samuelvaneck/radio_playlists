# frozen_string_literal: true

class TrackScraper::GnrApiProcessor < TrackScraper
  def last_played_song
    response = make_request
    return false if response.blank?

    @raw_response = response
    track = response.dig('stations', 'gnr')
    return false if track.blank?

    @artist_name = track['artist']
    @title = TitleSanitizer.sanitize(track['title']).titleize
    @broadcasted_at = Time.zone.now
    true
  rescue StandardError => e
    Rails.logger.info e
    ExceptionNotifier.notify(e)
    false
  end
end
