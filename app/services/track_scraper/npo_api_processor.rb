# frozen_string_literal: true

class TrackScraper::NpoApiProcessor < TrackScraper
  def last_played_song
    response = make_request
    raise StandardError if response.blank?

    @raw_response = response
    track = response.dig(:data, 0)
    return false if track.blank?

    @artist_name = CGI.unescapeHTML(track[:artist]).titleize
    @title = TitleSanitizer.sanitize(CGI.unescapeHTML(track[:title])).titleize
    @broadcasted_at = Time.find_zone('Amsterdam').parse(track[:startdatetime]) || Time.zone.now
    @spotify_url = track[:spotify_url]
    true
  rescue StandardError => e
    Rails.logger.warn("NpoApiProcessor: #{e.message}")
    ExceptionNotifier.notify_new_relic(e)
    false
  end
end
