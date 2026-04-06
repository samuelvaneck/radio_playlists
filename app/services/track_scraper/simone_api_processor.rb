# frozen_string_literal: true

class TrackScraper::SimoneApiProcessor < TrackScraper
  def last_played_song
    response = fetch_playlist
    return false if response.blank?

    @raw_response = response
    track = response.first
    return false if track.blank?

    @artist_name = track['artist'].titleize
    @title = TitleSanitizer.sanitize(track['title']).titleize
    @broadcasted_at = Time.zone.parse(track['timestamp'])
    true
  rescue StandardError => e
    Rails.logger.warn("SimoneApiProcessor: #{e.message}")
    ExceptionNotifier.notify(e)
    false
  end

  private

  def fetch_playlist
    response = connection.get(@radio_station.url)
    return nil unless response.success?

    response.body
  end

  def connection
    Faraday.new(@radio_station.url) do |conn|
      conn.response :json
    end
  end
end
