# frozen_string_literal: true

class SongImportLogger
  attr_reader :log

  def initialize(radio_station:)
    @radio_station = radio_station
    @log = nil
  end

  def start_log(broadcasted_at: nil)
    @log = SongImportLog.create!(
      radio_station: @radio_station,
      broadcasted_at: broadcasted_at || Time.zone.now,
      status: :pending
    )
  end

  def log_recognition(recognizer)
    return unless @log && recognizer

    @log.update(
      recognized_artist: recognizer.artist_name,
      recognized_title: recognizer.title,
      recognized_isrc: recognizer.isrc_code,
      recognized_spotify_url: recognizer.spotify_url,
      recognized_raw_response: recognizer.result || {},
      import_source: :recognition,
      broadcasted_at: recognizer.broadcasted_at || @log.broadcasted_at
    )
  end

  def log_acoustid(recognizer)
    return unless @log && recognizer

    @log.update(
      acoustid_artist: recognizer.artist_name,
      acoustid_title: recognizer.title,
      acoustid_recording_id: recognizer.recording_id,
      acoustid_score: recognizer.score,
      acoustid_raw_response: recognizer.result || {}
    )
  end

  def log_scraping(scraper, raw_response: nil)
    return unless @log && scraper

    @log.update(
      scraped_artist: scraper.artist_name,
      scraped_title: scraper.title,
      scraped_isrc: scraper.isrc_code,
      scraped_spotify_url: scraper.spotify_url,
      scraped_raw_response: raw_response || {},
      import_source: :scraping,
      broadcasted_at: scraper.broadcasted_at || @log.broadcasted_at
    )
  end

  def log_spotify(spotify_track)
    return unless @log && spotify_track

    @log.update(
      spotify_artist: extract_spotify_artist(spotify_track),
      spotify_title: spotify_track.title,
      spotify_track_id: spotify_track.id,
      spotify_isrc: spotify_track.isrc,
      spotify_raw_response: slim_spotify_response(spotify_track.track)
    )
  end

  def log_deezer(deezer_track)
    return unless @log && deezer_track

    @log.update(
      deezer_artist: extract_deezer_artist(deezer_track),
      deezer_title: deezer_track.title,
      deezer_track_id: deezer_track.id,
      deezer_raw_response: deezer_track.track || {}
    )
  end

  def log_itunes(itunes_track)
    return unless @log && itunes_track

    @log.update(
      itunes_artist: extract_itunes_artist(itunes_track),
      itunes_title: itunes_track.title,
      itunes_track_id: itunes_track.id,
      itunes_raw_response: itunes_track.track || {}
    )
  end

  def log_llm(action:, raw_response:)
    return unless @log

    @log.update(
      llm_action: action,
      llm_raw_response: raw_response || {}
    )
  end

  def complete_log(song:, air_play:)
    return unless @log

    @log.update(
      song: song,
      air_play: air_play,
      status: :success
    )
  end

  def fail_log(reason:)
    return unless @log

    @log.update(
      status: :failed,
      failure_reason: sanitize_reason(reason)
    )
  end

  def skip_log(reason:)
    return unless @log

    @log.update(
      status: :skipped,
      failure_reason: sanitize_reason(reason)
    )
  end

  private

  def sanitize_reason(reason)
    reason.to_s.truncate(500).gsub(%r{/Users/\S+}, '[PATH]')
  end

  def extract_spotify_artist(spotify_track)
    return nil unless spotify_track.artists

    spotify_track.artists.filter_map { |a| a&.dig('name') }.join(', ')
  end

  # Spotify track responses include an `available_markets` array (~1 KB of
  # country codes) on both the track and album. Nothing in the app reads it,
  # so drop it before storing the raw response to keep SongImportLog rows lean.
  def slim_spotify_response(track_hash)
    return {} if track_hash.blank?

    trimmed = track_hash.except('available_markets')
    trimmed['album'] = trimmed['album'].except('available_markets') if trimmed['album'].is_a?(Hash)
    trimmed
  end

  def extract_deezer_artist(deezer_track)
    return nil unless deezer_track.respond_to?(:artists) && deezer_track.artists

    Array.wrap(deezer_track.artists).map { |a| a.is_a?(Hash) ? a['name'] : a }.join(', ')
  end

  def extract_itunes_artist(itunes_track)
    return nil unless itunes_track.respond_to?(:artists) && itunes_track.artists

    Array.wrap(itunes_track.artists).map { |a| a.is_a?(Hash) ? a['name'] : a }.join(', ')
  end
end
