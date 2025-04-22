# frozen_string_literal: true

class TrackScraper::NpoApiProcessor < TrackScraper
  def last_played_song
    response = make_request
    raise StandardError if response.blank?

    track = response.dig(:data, 0)
    @artist_name = CGI.unescapeHTML(track[:artist]).titleize
    @title = CGI.unescapeHTML(track[:title]).titleize
    @broadcasted_at = Time.find_zone('Amsterdam').parse(track[:startdatetime])
    @spotify_url = track[:spotify_url]
    true
  rescue StandardError => e
    Rails.logger.info(e.message)
    ExceptionNotifier.notify_new_relic(e)
    false
  end
end
