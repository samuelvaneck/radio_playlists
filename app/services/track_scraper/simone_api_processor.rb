# frozen_string_literal: true

class TrackScraper::SimoneApiProcessor < TrackScraper
  # Window we treat as "the same song still playing" — longer than any
  # reasonable Simone track. While a song is in this window, we reuse its
  # broadcasted_at so SongImporter#recently_imported? dedupes naturally.
  SAME_SONG_WINDOW = 10.minutes

  def last_played_song
    track = fetch_now_playing
    return false if track.blank?

    artist = track['artist'].to_s.titleize
    title = TitleSanitizer.sanitize(track['title'].to_s).titleize
    return false if artist.blank? || title.blank?

    @raw_response = track
    @artist_name = artist
    @title = title
    @broadcasted_at = broadcasted_at_for(artist, title)
    true
  rescue StandardError => e
    Rails.logger.warn("SimoneApiProcessor: #{e.message}")
    ExceptionNotifier.notify(e)
    false
  end

  private

  # The /playlist/nowplaying endpoint has no timestamp. If the most recent log
  # for this station is the same song within SAME_SONG_WINDOW, reuse its
  # broadcasted_at — SongImporter#recently_imported? then matches and skips
  # the duplicate scrape. New song → fresh Time.zone.now.
  def broadcasted_at_for(artist, title)
    last = SongImportLog
             .where(radio_station: @radio_station, created_at: SAME_SONG_WINDOW.ago..)
             .where.not(broadcasted_at: nil)
             .order(created_at: :desc)
             .first

    if last && last.scraped_artist == artist && last.scraped_title == title
      last.broadcasted_at
    else
      Time.zone.now
    end
  end

  def fetch_now_playing
    response = connection.get(@radio_station.url)
    return nil unless response.success?

    response.body
  end

  def connection
    @connection ||= Faraday.new(@radio_station.url) do |conn|
      conn.options.timeout = 10
      conn.options.open_timeout = 5
      conn.response :json
    end
  end
end
