# frozen_string_literal: true

class TrackScraper::SimoneApiProcessor < TrackScraper
  def last_played_song
    response = fetch_playlist
    return false if response.blank?

    @raw_response = response
    track = pick_track(response)
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

  # The Simone API returns the most-recent ~16 tracks. Pick the oldest one we
  # haven't logged yet so a backlog (long DJ shows, missed scrapes) drains over
  # successive ticks. Falls back to the newest track when every entry is already
  # in SongImportLog — SongImporter#recently_imported? dedupes that case.
  def pick_track(response)
    sorted = response.sort_by { |t| Time.zone.parse(t['timestamp']) }
    keys = recent_log_keys
    sorted.find { |t| keys.exclude?(log_key_for(t)) } || sorted.last
  end

  def log_key_for(track)
    [
      track['artist'].titleize,
      TitleSanitizer.sanitize(track['title']).titleize,
      Time.zone.parse(track['timestamp'])
    ]
  end

  def recent_log_keys
    SongImportLog
      .where(radio_station: @radio_station, created_at: 1.hour.ago..)
      .pluck(:scraped_artist, :scraped_title, :broadcasted_at)
      .to_set
  end

  def fetch_playlist
    response = connection.get(@radio_station.url)
    return nil unless response.success?

    response.body
  end

  def connection
    @connection ||= Faraday.new(@radio_station.url) do |conn|
      conn.response :json
    end
  end
end
