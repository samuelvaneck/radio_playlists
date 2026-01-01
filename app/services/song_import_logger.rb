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
      import_source: :recognition
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
      import_source: :scraping
    )
  end

  def log_spotify(spotify_track)
    return unless @log && spotify_track

    @log.update(
      spotify_artist: extract_spotify_artist(spotify_track),
      spotify_title: spotify_track.title,
      spotify_track_id: spotify_track.id,
      spotify_isrc: spotify_track.isrc,
      spotify_raw_response: spotify_track.track || {}
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
      failure_reason: reason
    )
  end

  def skip_log(reason:)
    return unless @log

    @log.update(
      status: :skipped,
      failure_reason: reason
    )
  end

  private

  def extract_spotify_artist(spotify_track)
    return nil unless spotify_track.artists

    spotify_track.artists.map { |a| a['name'] }.join(', ')
  end

  def extract_deezer_artist(deezer_track)
    return nil unless deezer_track.respond_to?(:artists) && deezer_track.artists

    Array.wrap(deezer_track.artists).map { |a| a.is_a?(Hash) ? a['name'] : a }.join(', ')
  end

  def extract_itunes_artist(itunes_track)
    return nil unless itunes_track.respond_to?(:artists) && itunes_track.artists

    Array.wrap(itunes_track.artists).join(', ')
  end
end
