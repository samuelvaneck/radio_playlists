# frozen_string_literal: true

class TrackScrapper::KinkApiProcessor < TrackScraper
  def last_played_song
    uri = URI @radio_station.url
    json = JSON(make_request).with_indifferent_access
    raise StandardError if json.blank?

    track = json[:extended][:kink]
    @artist_name = track[:artist].titleize
    @title = track[:title].titleize
    @broadcast_timestamp = Time.find_zone('Amsterdam').parse(Time.zone.now)
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
