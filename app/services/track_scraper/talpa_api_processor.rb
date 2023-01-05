# frozen_string_literal: true

class TrackScraper::TalpaApiProcessor < TrackScraper
  def last_played_song
    uri = URI @radio_station.url
    api_header = { 'x-api-key': ENV['TALPA_API_KEY'] }
    json = JSON(make_request(api_header))
    raise StandardError if json.blank?
    raise StandardError, json['errors'] if json['errors'].present?

    track = json.dig('data', 'getStation', 'playouts')[0]
    @artist_name = track.dig('track', 'artistName').titleize
    @title = track.dig('track', 'title').titleize
    @broadcast_timestamp = Time.find_zone('Amsterdam').parse(track['broadcastDate'])
    @isrc_code = track.dig('track', 'isrc')
    true
  rescue Net::ReadTimeout => _e
    Rails.logger.info "#{uri.host}:#{uri.port} is NOT reachable (ReadTimeout)"
    false
  rescue Net::OpenTimeout => _e
    Rails.logger.info "#{uri.host}:#{uri.port} is NOT reachable (OpenTimeout)"
    false
  rescue StandardError => e
    Rails.logger.info e.try(:message)
    false
  end
end
