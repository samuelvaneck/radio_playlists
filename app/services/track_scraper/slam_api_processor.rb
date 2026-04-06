# frozen_string_literal: true

class TrackScraper::SlamApiProcessor < TrackScraper
  def last_played_song
    response = make_request
    return false if response.blank?

    @raw_response = response
    track = response[:data][:song]
    return false if track.blank?

    @artist_name = track[:artist].titleize
    @title = TitleSanitizer.sanitize(track[:title]).titleize
    @broadcasted_at = Time.zone.now
    true
  rescue StandardError => e
    Rails.logger.warn("SlamApiProcessor: #{e.message}")
    ExceptionNotifier.notify(e)
    false
  end
end
