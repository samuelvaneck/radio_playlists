# frozen_string_literal: true

# Finds and fixes airplays that were linked to the wrong song. Two detectors:
#
#  - Title mismatch: the scraped/recognized title in the import log differs
#    from the linked song's title by more than the JaroWinkler threshold.
#  - Spotify ID mismatch: the import log carries a spotify_track_id that
#    points to a different canonical song record than the one the airplay is
#    linked to (e.g., when artist-distance validation rejected a valid Spotify
#    match and SongExtractor fell back to an existing look-alike).
#
# When a mismatch is found, the airplay is reassigned to the correct song
# (found or created based on the import log's Spotify data).
class MismatchedAirplayRepair
  TITLE_SIMILARITY_THRESHOLD = 70

  attr_reader :results

  def initialize(dry_run: true, limit: 1000)
    @dry_run = dry_run
    @limit = limit
    @results = { checked: 0, mismatched: 0, fixed: 0, errors: [] }
  end

  def run
    mismatched_logs.find_each do |log|
      @results[:checked] += 1
      process_log(log)
    end

    @results
  end

  private

  def mismatched_logs
    SongImportLog.includes(:song, :air_play, song: :artists)
      .where(status: :success)
      .where.not(song_id: nil, air_play_id: nil)
      .order(created_at: :desc)
      .limit(@limit)
  end

  def process_log(log)
    song = log.song
    return if song.blank?

    reason = detect_mismatch(log, song)
    return if reason.blank?

    @results[:mismatched] += 1
    correct_song = find_or_create_correct_song(log)

    log_mismatch(log, song, reason, correct_song)

    return if @dry_run || correct_song.blank? || correct_song.id == song.id

    fix_airplay(log, correct_song)
  rescue StandardError => e
    @results[:errors] << { log_id: log.id, error: e.message }
  end

  def detect_mismatch(log, song)
    detect_title_mismatch(log, song) || detect_spotify_id_mismatch(log, song)
  end

  def detect_title_mismatch(log, song)
    import_title = import_title_for(log)
    return nil if import_title.blank?

    score = jaro_winkler_score(import_title, song.title)
    return nil if score >= TITLE_SIMILARITY_THRESHOLD

    { kind: :title, import_title: import_title, title_score: score }
  end

  def detect_spotify_id_mismatch(log, song)
    return nil if log.spotify_track_id.blank?
    return nil if song.id_on_spotify == log.spotify_track_id

    canonical = Song.find_by(id_on_spotify: log.spotify_track_id)
    return nil if canonical.blank? || canonical.id == song.id

    { kind: :spotify_id, spotify_track_id: log.spotify_track_id, canonical_id: canonical.id }
  end

  def import_title_for(log)
    if log.spotify_title.present?
      log.spotify_title
    elsif log.scraped_title.present?
      log.scraped_title
    elsif log.recognized_title.present?
      log.recognized_title
    end
  end

  def import_artist_for(log)
    if log.spotify_artist.present?
      log.spotify_artist
    elsif log.scraped_artist.present?
      log.scraped_artist
    elsif log.recognized_artist.present?
      log.recognized_artist
    end
  end

  def find_or_create_correct_song(log)
    # Try finding by Spotify track ID first (most reliable)
    if log.spotify_track_id.present?
      song = Song.find_by(id_on_spotify: log.spotify_track_id)
      return song if song.present?
    end

    # Try finding by exact artist + title match
    import_title = import_title_for(log)
    import_artist = import_artist_for(log)
    return if import_title.blank? || import_artist.blank?

    artists = find_artists(import_artist)
    if artists.present?
      song = Song.joins(:artists)
               .where(artists: { id: artists.map(&:id) })
               .where('LOWER(songs.title) = ?', import_title.downcase)
               .first
      return song if song.present?
    end

    # Create new song from import log data
    create_song_from_log(log, artists)
  end

  def find_artists(artist_name)
    regex = Regexp.new(Song::MULTIPLE_ARTIST_REGEX, Regexp::IGNORECASE)
    names = if artist_name.match?(regex)
              artist_name.split(regex).map(&:strip).reject(&:blank?)
            else
              [artist_name]
            end

    names.filter_map do |name|
      Artist.find_by('LOWER(name) = ?', name.downcase)
    end
  end

  def create_song_from_log(log, artists)
    attrs = { title: import_title_for(log) }
    attrs[:id_on_spotify] = log.spotify_track_id if log.spotify_track_id.present?
    attrs[:spotify_song_url] = spotify_url_from_id(log.spotify_track_id) if log.spotify_track_id.present?
    attrs[:isrcs] = [log.spotify_isrc].compact

    song = Song.new(attrs)
    artists.each { |artist| song.artists << artist } if artists.present?
    song.save!
    song
  end

  def fix_airplay(log, correct_song)
    ActiveRecord::Base.transaction do
      air_play = log.air_play
      return if air_play.blank?

      air_play.update!(song: correct_song)
      log.update!(song: correct_song)
      @results[:fixed] += 1
    end
  end

  def jaro_winkler_score(str1, str2)
    (JaroWinkler.similarity(str1.downcase, str2.downcase) * 100).to_i
  end

  def spotify_url_from_id(track_id)
    "https://open.spotify.com/track/#{track_id}" if track_id.present?
  end

  def log_mismatch(log, wrong_song, reason, correct_song)
    $stdout.puts "  Log ##{log.id} | Station #{log.radio_station_id} | #{log.broadcasted_at&.strftime('%Y-%m-%d %H:%M')}"
    $stdout.puts "    Import:  #{import_artist_for(log)} - #{import_title_for(log)}"
    $stdout.puts "    Linked:  #{wrong_song.artists.map(&:name).join(', ')} - " \
                 "#{wrong_song.title} (song ##{wrong_song.id}, spotify: #{wrong_song.id_on_spotify || 'nil'})"
    log_reason(reason)
    log_fix(correct_song, wrong_song)
    $stdout.puts
  end

  def log_reason(reason)
    case reason[:kind]
    when :title
      $stdout.puts "    Reason:  title mismatch #{reason[:title_score]}% (threshold: #{TITLE_SIMILARITY_THRESHOLD}%)"
    when :spotify_id
      $stdout.puts "    Reason:  spotify_track_id #{reason[:spotify_track_id]} points to song ##{reason[:canonical_id]}"
    end
  end

  def log_fix(correct_song, wrong_song)
    if correct_song.blank?
      $stdout.puts '    Fix:     no matching song found, skipping'
    elsif correct_song.id == wrong_song.id
      $stdout.puts '    Fix:     already linked to correct song, skipping'
    else
      status = @dry_run ? 'would reassign' : 'reassigned'
      $stdout.puts "    Fix:     #{status} to #{correct_song.title} (song ##{correct_song.id})"
    end
  end
end
