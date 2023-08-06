# frozen_string_literal: true

class TrackScraper::GnrApiProcessor < TrackScraper
  def last_played_song
    @uri = URI @radio_station.url
    json = JSON(make_request).with_indifferent_access
    raise StandardError if json.blank?

    track = json[:pageProps][:homepage][:played_tracks][:data][0]
    @artist_name = track[:track][:data][:artist]
    @title = track[:track][:data][:title].titleize
    @broadcast_timestamp = Time.zone.now
    true
  rescue Net::ReadTimeout => _e
    Rails.logger.info "#{@uri.host}:#{@uri.port} is NOT reachable (ReadTimeout)"
    false
  rescue Net::OpenTimeout => _e
    Rails.logger.info "#{@uri.host}:#{@uri.port} is NOT reachable (OpenTimeout)"
    false
  rescue StandardError => e
    Rails.logger.info e
    false
  end
end
