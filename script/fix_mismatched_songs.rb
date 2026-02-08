# frozen_string_literal: true

# Script to identify and fix songs affected by the nil-matching bug
#
# The bug caused songs to be matched incorrectly when Spotify/ISRC lookups
# returned nil, linking unrelated songs together.
#
# Usage:
#   DRY RUN (identify only):
#     rails runner script/fix_mismatched_songs.rb
#
#   FIX MODE (apply fixes):
#     rails runner "ENV['FIX_MODE']='true'; load 'script/fix_mismatched_songs.rb'"
#
#   VERBOSE MODE (show more details):
#     rails runner "ENV['VERBOSE']='true'; load 'script/fix_mismatched_songs.rb'"

class MismatchedSongFixer
  MISMATCH_THRESHOLD = 0.7
  LOW_SIMILARITY_THRESHOLD = 0.8
  ARTIST_SIMILARITY_THRESHOLD = 0.8

  attr_reader :dry_run, :verbose, :affected_songs, :fixed_count, :error_count

  def initialize(dry_run: true, verbose: false)
    @dry_run = dry_run
    @verbose = verbose
    @affected_songs = []
    @fixed_count = 0
    @error_count = 0
  end

  def run
    print_header
    identify_mismatched_songs
    print_summary
    process_fixes if should_process_fixes?
  end

  private

  def print_header
    puts '=' * 80
    puts "Mismatched Song Fixer - #{dry_run ? 'DRY RUN' : 'FIX MODE'}"
    puts '=' * 80
    puts ''
  end

  def should_process_fixes?
    return false if affected_songs.empty?

    if dry_run
      puts "\nTo apply fixes, run with FIX_MODE=true"
      false
    else
      puts "\nProceeding with fixes..."
      true
    end
  end

  def process_fixes
    fix_affected_songs
    print_fix_summary
  end

  def identify_mismatched_songs
    puts "Scanning songs with Spotify data for mismatches...\n\n"
    Song.where.not(id_on_spotify: [nil, '']).find_each { |song| check_song_mismatch(song) }
  end

  def check_song_mismatch(song)
    mismatch_result = SongMismatchChecker.new(song, verbose).check
    return unless mismatch_result

    affected_songs << mismatch_result
    print_mismatch(mismatch_result)
  end

  def print_mismatch(info)
    puts "  [MISMATCH] Song ID: #{info[:song].id}"
    puts "    DB Title:      '#{info[:db_title]}'"
    puts "    DB Artists:    #{info[:db_artists].join(', ')}"
    puts "    Spotify Title: '#{info[:spotify_title]}'"
    puts "    Spotify Artists: #{info[:spotify_artists].join(', ')}"
    puts "    Similarity:    #{(info[:title_similarity] * 100).round}%"
    puts "    AirPlays:      #{info[:song].air_plays.count}"
    puts ''
  end

  def print_summary
    puts '=' * 80
    puts 'SUMMARY'
    puts '=' * 80
    puts "Total mismatched songs found: #{affected_songs.count}"
    puts "Total air_plays affected: #{affected_songs.sum { |info| info[:song].air_plays.count }}"
    puts ''
  end

  def fix_affected_songs
    affected_songs.each { |info| safe_fix_song(info) }
  end

  def safe_fix_song(info)
    SongFixer.new(info, verbose).fix
    @fixed_count += 1
  rescue StandardError => e
    @error_count += 1
    puts "  [ERROR] Failed to fix Song #{info[:song].id}: #{e.message}"
    puts e.backtrace.first(3).join("\n") if verbose
  end

  def print_fix_summary
    puts ''
    puts '=' * 80
    puts 'FIX SUMMARY'
    puts '=' * 80
    puts "Songs fixed: #{fixed_count}"
    puts "Errors: #{error_count}"
    puts '=' * 80
  end
end

# Helper class to check if a song has mismatched data
class SongMismatchChecker
  def initialize(song, verbose)
    @song = song
    @verbose = verbose
  end

  def check
    return nil if @song.id_on_spotify.blank?

    spotify_data = fetch_spotify_track
    return nil if spotify_data.nil?

    analyze_mismatch(spotify_data)
  rescue StandardError => e
    puts "  [ERROR] Song #{@song.id}: #{e.message}" if @verbose
    nil
  end

  private

  def fetch_spotify_track
    Rails.cache.fetch("fix_script_spotify_#{@song.id_on_spotify}", expires_in: 1.hour) do
      Spotify::TrackFinder::FindById.new(id_on_spotify: @song.id_on_spotify).execute
    end
  end

  def analyze_mismatch(spotify_data)
    spotify_title = spotify_data['name']
    spotify_artists = spotify_data['artists']&.map { |a| a['name'] } || []
    title_similarity = calculate_similarity(@song.title.downcase, spotify_title.downcase)
    song_artists = @song.artists.pluck(:name)

    log_low_similarity(spotify_title, title_similarity) if @verbose && title_similarity < 0.8

    return nil if title_similarity >= MismatchedSongFixer::MISMATCH_THRESHOLD || artists_match?(song_artists, spotify_artists)

    build_mismatch_info(spotify_data, spotify_title, spotify_artists, title_similarity, song_artists)
  end

  def log_low_similarity(spotify_title, similarity)
    return if similarity < MismatchedSongFixer::MISMATCH_THRESHOLD

    puts "  [OK but low similarity] Song #{@song.id}: '#{@song.title}' vs '#{spotify_title}' (#{(similarity * 100).round}%)"
  end

  def build_mismatch_info(spotify_data, spotify_title, spotify_artists, title_similarity, song_artists)
    {
      song: @song,
      db_title: @song.title,
      db_artists: song_artists,
      spotify_title: spotify_title,
      spotify_artists: spotify_artists,
      title_similarity: title_similarity,
      spotify_data: spotify_data
    }
  end

  def calculate_similarity(str1, str2)
    return 1.0 if str1 == str2
    return 0.0 if str1.blank? || str2.blank?

    JaroWinkler.similarity(str1, str2)
  end

  def artists_match?(db_artists, spotify_artists)
    return false if db_artists.blank? || spotify_artists.blank?

    db_normalized = db_artists.map { |a| normalize_artist(a) }
    spotify_normalized = spotify_artists.map { |a| normalize_artist(a) }

    (db_normalized & spotify_normalized).any? || fuzzy_artist_match?(db_normalized, spotify_normalized)
  end

  def fuzzy_artist_match?(db_normalized, spotify_normalized)
    db_normalized.any? { |db_a| spotify_normalized.any? { |sp_a| calculate_similarity(db_a, sp_a) > 0.8 } }
  end

  def normalize_artist(name)
    name.downcase.gsub(/[^a-z0-9]/, '')
  end
end

# Helper class to fix a mismatched song
class SongFixer
  def initialize(info, verbose)
    @info = info
    @verbose = verbose
    @song = info[:song]
    @spotify_data = info[:spotify_data]
  end

  def fix
    puts "Fixing Song ID: #{@song.id} ('#{@song.title}' -> '#{@info[:spotify_title]}')"

    ActiveRecord::Base.transaction do
      correct_song = find_correct_song
      if correct_song && correct_song.id != @song.id
        move_air_plays_to(correct_song)
      else
        update_with_correct_data
      end
    end
  end

  private

  def find_correct_song
    @info[:spotify_artists].each do |artist_name|
      artist = Artist.find_by('LOWER(name) = ?', artist_name.downcase)
      next unless artist

      existing = Song.joins(:artists)
                   .where(artists: { id: artist.id })
                   .where('LOWER(songs.title) = ?', @info[:spotify_title].downcase)
                   .first
      return existing if existing
    end
    nil
  end

  def move_air_plays_to(correct_song)
    air_play_count = @song.air_plays.count
    # rubocop:disable Rails/SkipsModelValidations
    @song.air_plays.update_all(song_id: correct_song.id)
    SongImportLog.where(song_id: @song.id).update_all(song_id: correct_song.id)
    # rubocop:enable Rails/SkipsModelValidations

    clear_incorrect_song_data
    puts "  -> Moved #{air_play_count} air_plays to existing Song ID: #{correct_song.id} ('#{correct_song.title}')"
  end

  def clear_incorrect_song_data
    @song.update!(id_on_spotify: nil, isrc: nil, spotify_song_url: nil, spotify_artwork_url: nil)
    @song.artists.clear
  end

  def update_with_correct_data
    correct_artists = find_or_create_artists
    update_song_attributes
    update_song_artists(correct_artists)
    puts '  -> Updated song with correct Spotify data'
  end

  def update_song_attributes
    @song.update!(
      title: @info[:spotify_title],
      isrc: @spotify_data.dig('external_ids', 'isrc'),
      spotify_song_url: @spotify_data.dig('external_urls', 'spotify'),
      spotify_artwork_url: @spotify_data.dig('album', 'images', 0, 'url'),
      spotify_preview_url: @spotify_data['preview_url']
    )
  end

  def update_song_artists(correct_artists)
    @song.artists.clear
    correct_artists.each { |artist| @song.artists << artist unless @song.artists.include?(artist) }
  end

  def find_or_create_artists
    (@spotify_data['artists'] || []).map { |artist_data| find_or_create_artist(artist_data) }
  end

  def find_or_create_artist(artist_data)
    artist_name = artist_data['name']
    spotify_id = artist_data['id']

    existing = Artist.find_by(id_on_spotify: spotify_id) ||
               Artist.find_by('LOWER(name) = ?', artist_name.downcase)

    return update_existing_artist(existing, spotify_id) if existing

    Artist.create!(name: artist_name, id_on_spotify: spotify_id)
  end

  def update_existing_artist(artist, spotify_id)
    artist.update!(id_on_spotify: spotify_id) if artist.id_on_spotify.blank?
    artist
  end
end

# Run the script
dry_run = ENV['FIX_MODE'] != 'true'
verbose = ENV['VERBOSE'] == 'true'

fixer = MismatchedSongFixer.new(dry_run: dry_run, verbose: verbose)
fixer.run
