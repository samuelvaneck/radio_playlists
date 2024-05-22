# frozen_string_literal: true

class TrackScraper::NpoApiProcessor < TrackScraper
  def last_played_song
    uri = URI @radio_station.url
    json = JSON(make_request).with_indifferent_access
    raise StandardError if json.blank?

    track = json[:data][0]
    @artist_name = CGI.unescapeHTML(track[:artist]).titleize
    @title = CGI.unescapeHTML(track[:title]).titleize
    @broadcasted_at = Time.find_zone('Amsterdam').parse(track[:startdatetime])
    @spotify_url = track[:spotify_url]
    true
  rescue Net::ReadTimeout => _e
    Rails.logger.info "#{uri.host}:#{uri.port} is NOT reachable (ReadTimeout)"
    false
  rescue Net::OpenTimeout => _e
    Rails.logger.info "#{uri.host}:#{uri.port} is NOT reachable (OpenTimeout)"
    false
  rescue StandardError => e
    Rails.logger.info e
    false
  end
end
