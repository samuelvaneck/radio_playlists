# frozen_string_literal: true

class TrackScraper::SimoneApiProcessor < TrackScraper
  # Cap drain to the last hour so we don't backfill stale history when the API
  # window stretches further back. Within that window prefer the *newest*
  # unlogged track so the last-imported airplay reflects what's currently on
  # air — keeps the radio station "now playing" widget correct. Older unlogged
  # tracks still drain on subsequent ticks (in reverse chronological order).
  TRACK_LOOKBACK = 1.hour

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

  def pick_track(response)
    cutoff = TRACK_LOOKBACK.ago
    recent = response.select { |t| Time.zone.parse(t['timestamp']) >= cutoff }
    return nil if recent.empty?

    newest_first = recent.sort_by { |t| Time.zone.parse(t['timestamp']) }.reverse
    keys = recent_log_keys
    newest_first.find { |t| keys.exclude?(log_key_for(t)) } || newest_first.first
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
