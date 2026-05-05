# frozen_string_literal: true

# Recovers SongImportLogs that got stuck in `pending` status — typically because
# the import job was killed mid-flight (OOM, double Timeout::Error, exception
# inside the rescue's notification side-effects) before reaching a terminal
# status.
#
# For each stuck log with a confirmed Spotify track:
#  1. Resolve the canonical Song by spotify_track_id (preferred) or by
#     artist+title; fall back to creating one from the logged Spotify data.
#  2. Find an existing AirPlay at (radio_station, song, broadcasted_at). If one
#     already exists (the original import created it but never updated the log),
#     reuse it. Otherwise create a new AirPlay.
#  3. Mark the log `success` linked to the song and air_play.
#
# Logs without a spotify_track_id are skipped — too risky to back-fill from
# scraped/recognized data without an authoritative identity. Logs younger than
# `min_age` are skipped to avoid racing in-flight imports.
class StuckPendingLogRecovery
  DEFAULT_MIN_AGE = 10.minutes

  attr_reader :results

  def initialize(dry_run: true, limit: 500, min_age: DEFAULT_MIN_AGE)
    @dry_run = dry_run
    @limit = limit
    @min_age = min_age
    @results = {
      checked: 0, recovered: 0, reused_air_play: 0, created_air_play: 0,
      skipped: 0, errors: []
    }
  end

  def run
    stuck_logs.find_each do |log|
      @results[:checked] += 1
      process_log(log)
    end

    @results
  end

  private

  def stuck_logs
    SongImportLog.includes(:radio_station)
      .where(status: :pending)
      .where.not(spotify_track_id: nil)
      .where(created_at: ...@min_age.ago)
      .order(created_at: :desc)
      .limit(@limit)
  end

  def process_log(log)
    song = find_or_create_song(log)
    if song.blank?
      @results[:skipped] += 1
      log_skip(log, 'could not resolve song from log data')
      return
    end

    existing_air_play = find_existing_air_play(log, song)
    log_recovery(log, song, existing_air_play)
    return if @dry_run

    air_play = existing_air_play || AirPlay.create!(air_play_attributes(log, song))
    log.update!(status: :success, song: song, air_play: air_play)
    @results[:recovered] += 1
    @results[existing_air_play ? :reused_air_play : :created_air_play] += 1
  rescue StandardError => e
    @results[:errors] << { log_id: log.id, error: e.message }
  end

  def find_or_create_song(log)
    song = Song.find_by(id_on_spotify: log.spotify_track_id)
    return song if song.present?

    title = import_title_for(log)
    artist_name = import_artist_for(log)
    return nil if title.blank? || artist_name.blank?

    artists = find_artists(artist_name)
    if artists.present?
      existing = Song.joins(:artists)
                   .where(artists: { id: artists.map(&:id) })
                   .where('LOWER(songs.title) = ?', title.downcase)
                   .first
      return existing if existing.present?
    end

    return nil if @dry_run

    create_song_from_log(log, title, artists)
  end

  def import_title_for(log)
    log.spotify_title.presence || log.recognized_title.presence || log.scraped_title.presence
  end

  def import_artist_for(log)
    log.spotify_artist.presence || log.recognized_artist.presence || log.scraped_artist.presence
  end

  def find_artists(artist_name)
    regex = Regexp.new(Song::MULTIPLE_ARTIST_REGEX, Regexp::IGNORECASE)
    names = if artist_name.match?(regex)
              artist_name.split(regex).map(&:strip).reject(&:blank?)
            else
              [artist_name]
            end

    names.filter_map { |name| Artist.find_by('LOWER(name) = ?', name.downcase) }
  end

  def create_song_from_log(log, title, artists)
    song = Song.new(
      title: title,
      id_on_spotify: log.spotify_track_id,
      spotify_song_url: "https://open.spotify.com/track/#{log.spotify_track_id}",
      isrcs: [log.spotify_isrc].compact
    )
    artists.each { |artist| song.artists << artist } if artists.present?
    song.save!
    song
  end

  def find_existing_air_play(log, song)
    return nil if log.broadcasted_at.blank?

    AirPlay.find_by(
      radio_station_id: log.radio_station_id,
      song_id: song.id,
      broadcasted_at: log.broadcasted_at
    )
  end

  def air_play_attributes(log, song)
    {
      radio_station: log.radio_station,
      song: song,
      broadcasted_at: log.broadcasted_at,
      scraper_import: log.import_source == 'scraping',
      status: :confirmed
    }
  end

  def log_recovery(log, song, existing_air_play)
    action = if existing_air_play
               @dry_run ? 'would attach existing air_play' : 'attaching existing air_play'
             else
               @dry_run ? 'would create air_play' : 'creating air_play'
             end
    $stdout.puts "  Log ##{log.id} | Station #{log.radio_station_id} | " \
                 "#{log.broadcasted_at&.strftime('%Y-%m-%d %H:%M')} | " \
                 "#{import_artist_for(log)} - #{import_title_for(log)} | " \
                 "song ##{song.id} | #{action}" \
                 "#{existing_air_play ? " ##{existing_air_play.id}" : ''}"
  end

  def log_skip(log, reason)
    $stdout.puts "  Log ##{log.id} | skipped: #{reason}"
  end
end
