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
  attr_reader :dry_run, :verbose, :affected_songs, :fixed_count, :error_count

  def initialize(dry_run: true, verbose: false)
    @dry_run = dry_run
    @verbose = verbose
    @affected_songs = []
    @fixed_count = 0
    @error_count = 0
  end

  def run
    puts '=' * 80
    puts "Mismatched Song Fixer - #{dry_run ? 'DRY RUN' : 'FIX MODE'}"
    puts '=' * 80
    puts ''

    identify_mismatched_songs
    print_summary

    if !dry_run && affected_songs.any?
      puts "\nProceeding with fixes..."
      fix_affected_songs
      print_fix_summary
    elsif dry_run && affected_songs.any?
      puts "\nTo apply fixes, run with FIX_MODE=true"
    end
  end

  private

  def identify_mismatched_songs
    puts "Scanning songs with Spotify data for mismatches...\n\n"

    # Find songs that have Spotify IDs and check if they match
    Song.where.not(id_on_spotify: [nil, '']).find_each do |song|
      check_song_mismatch(song)
    end
  end

  def check_song_mismatch(song)
    return if song.id_on_spotify.blank?

    # Fetch actual Spotify data for this ID
    spotify_data = fetch_spotify_track(song.id_on_spotify)
    return if spotify_data.nil?

    spotify_title = spotify_data['name']
    spotify_artists = spotify_data['artists']&.map { |a| a['name'] } || []

    # Check if there's a significant mismatch
    title_similarity = calculate_similarity(song.title.downcase, spotify_title.downcase)
    song_artists = song.artists.pluck(:name)

    # Check artist overlap
    artist_match = artists_match?(song_artists, spotify_artists)

    # Flag as mismatched if title similarity is low AND artists don't match
    if title_similarity < 0.5 && !artist_match
      mismatch_info = {
        song: song,
        db_title: song.title,
        db_artists: song_artists,
        spotify_title: spotify_title,
        spotify_artists: spotify_artists,
        title_similarity: title_similarity,
        spotify_data: spotify_data
      }
      affected_songs << mismatch_info
      print_mismatch(mismatch_info)
    elsif verbose && title_similarity < 0.8
      puts "  [OK but low similarity] Song #{song.id}: '#{song.title}' vs '#{spotify_title}' (#{(title_similarity * 100).round}%)"
    end
  rescue StandardError => e
    puts "  [ERROR] Song #{song.id}: #{e.message}" if verbose
  end

  def fetch_spotify_track(spotify_id)
    Rails.cache.fetch("fix_script_spotify_#{spotify_id}", expires_in: 1.hour) do
      Spotify::TrackFinder::FindById.new(id_on_spotify: spotify_id).execute
    end
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

    # Check if any artist matches
    (db_normalized & spotify_normalized).any? ||
      db_normalized.any? { |db_a| spotify_normalized.any? { |sp_a| calculate_similarity(db_a, sp_a) > 0.8 } }
  end

  def normalize_artist(name)
    name.downcase.gsub(/[^a-z0-9]/, '')
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
    puts "SUMMARY"
    puts '=' * 80
    puts "Total mismatched songs found: #{affected_songs.count}"
    puts "Total air_plays affected: #{affected_songs.sum { |info| info[:song].air_plays.count }}"
    puts ''
  end

  def fix_affected_songs
    affected_songs.each do |info|
      fix_song(info)
    rescue StandardError => e
      @error_count += 1
      puts "  [ERROR] Failed to fix Song #{info[:song].id}: #{e.message}"
      puts e.backtrace.first(3).join("\n") if verbose
    end
  end

  def fix_song(info)
    song = info[:song]
    spotify_data = info[:spotify_data]

    puts "Fixing Song ID: #{song.id} ('#{song.title}' -> '#{info[:spotify_title]}')"

    ActiveRecord::Base.transaction do
      # Option 1: Find if the correct song already exists
      correct_song = find_correct_song(info)

      if correct_song && correct_song.id != song.id
        # Move air_plays to the correct song
        move_air_plays(song, correct_song)
        @fixed_count += 1
        puts "  -> Moved air_plays to existing Song ID: #{correct_song.id} ('#{correct_song.title}')"
      else
        # Option 2: Update the current song with correct data
        update_song_with_correct_data(song, info)
        @fixed_count += 1
        puts "  -> Updated song with correct Spotify data"
      end
    end
  end

  def find_correct_song(info)
    spotify_title = info[:spotify_title]
    spotify_artists = info[:spotify_artists]

    # Try to find by the Spotify title and artists
    spotify_artists.each do |artist_name|
      artist = Artist.find_by('LOWER(name) = ?', artist_name.downcase)
      next unless artist

      existing = Song.joins(:artists)
                     .where(artists: { id: artist.id })
                     .where('LOWER(songs.title) = ?', spotify_title.downcase)
                     .first
      return existing if existing
    end

    nil
  end

  def move_air_plays(from_song, to_song)
    air_play_count = from_song.air_plays.count
    from_song.air_plays.update_all(song_id: to_song.id)
    puts "  -> Moved #{air_play_count} air_plays from Song #{from_song.id} to Song #{to_song.id}"

    # Also update import logs
    SongImportLog.where(song_id: from_song.id).update_all(song_id: to_song.id)

    # Clear the incorrect song's data to prevent future matches
    from_song.update!(
      id_on_spotify: nil,
      isrc: nil,
      spotify_song_url: nil,
      spotify_artwork_url: nil
    )
    from_song.artists.clear
  end

  def update_song_with_correct_data(song, info)
    spotify_data = info[:spotify_data]

    # Get correct artist info
    correct_artists = find_or_create_artists(spotify_data['artists'] || [])

    # Update song
    song.update!(
      title: info[:spotify_title],
      isrc: spotify_data.dig('external_ids', 'isrc'),
      spotify_song_url: spotify_data.dig('external_urls', 'spotify'),
      spotify_artwork_url: spotify_data.dig('album', 'images', 0, 'url'),
      spotify_preview_url: spotify_data['preview_url']
    )

    # Update artists
    song.artists.clear
    correct_artists.each { |artist| song.artists << artist unless song.artists.include?(artist) }
  end

  def find_or_create_artists(spotify_artists_data)
    spotify_artists_data.map do |artist_data|
      artist_name = artist_data['name']
      spotify_id = artist_data['id']

      existing = Artist.find_by(id_on_spotify: spotify_id) ||
                 Artist.find_by('LOWER(name) = ?', artist_name.downcase)

      if existing
        # Update with Spotify ID if missing
        existing.update!(id_on_spotify: spotify_id) if existing.id_on_spotify.blank?
        existing
      else
        Artist.create!(name: artist_name, id_on_spotify: spotify_id)
      end
    end
  end

  def print_fix_summary
    puts ''
    puts '=' * 80
    puts "FIX SUMMARY"
    puts '=' * 80
    puts "Songs fixed: #{fixed_count}"
    puts "Errors: #{error_count}"
    puts '=' * 80
  end
end

# Run the script
dry_run = ENV['FIX_MODE'] != 'true'
verbose = ENV['VERBOSE'] == 'true'

fixer = MismatchedSongFixer.new(dry_run: dry_run, verbose: verbose)
fixer.run
