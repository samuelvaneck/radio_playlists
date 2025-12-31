# frozen_string_literal: true

namespace :data_repair do
  desc 'Verify songs against Spotify data and report mismatches. Usage: rake data_repair:verify_songs[100]'
  task :verify_songs, [:limit] => :environment do |_t, args|
    limit = (args[:limit] || 100).to_i
    puts "Verifying up to #{limit} songs against Spotify..."
    puts '=' * 80

    songs = Song.where.not(id_on_spotify: nil).order(updated_at: :desc).limit(limit)
    mismatches = []

    songs.find_each.with_index do |song, index|
      print "\rProcessing #{index + 1}/#{songs.count}..."

      result = fetch_spotify_data(song.id_on_spotify)
      next if result.blank?

      mismatch = detect_mismatch(song, result)
      mismatches << mismatch if mismatch.present?

      sleep 0.1 # Rate limiting for Spotify API
    end

    puts "\n\n"
    print_mismatch_report(mismatches)
  end

  desc 'Verify songs updated in a time range. Usage: rake data_repair:verify_range["2024-12-30 00:00","2024-12-31 23:59"]'
  task :verify_range, %i[start_time end_time] => :environment do |_t, args|
    start_time = Time.zone.parse(args[:start_time])
    end_time = Time.zone.parse(args[:end_time])

    abort 'Please provide start and end times' if start_time.blank? || end_time.blank?

    songs = Song.where.not(id_on_spotify: nil).where(updated_at: start_time..end_time)
    puts "Verifying #{songs.count} songs updated between #{start_time} and #{end_time}..."
    puts '=' * 80

    mismatches = []

    songs.find_each.with_index do |song, index|
      print "\rProcessing #{index + 1}/#{songs.count}..."

      result = fetch_spotify_data(song.id_on_spotify)
      next if result.blank?

      mismatch = detect_mismatch(song, result)
      mismatches << mismatch if mismatch.present?

      sleep 0.1
    end

    puts "\n\n"
    print_mismatch_report(mismatches)
  end

  desc 'Fix corrupted songs by re-fetching from Spotify. Usage: rake data_repair:fix_songs[100]'
  task :fix_songs, [:limit] => :environment do |_t, args|
    limit = (args[:limit] || 100).to_i
    puts "Checking and fixing up to #{limit} songs..."
    puts '=' * 80

    songs = Song.where.not(id_on_spotify: nil).order(updated_at: :desc).limit(limit)
    fixed_count = 0

    songs.find_each.with_index do |song, index|
      print "\rProcessing #{index + 1}/#{songs.count}..."

      result = fetch_spotify_data(song.id_on_spotify)
      next if result.blank?

      mismatch = detect_mismatch(song, result)
      next if mismatch.blank?

      fix_song(song, result, mismatch)
      fixed_count += 1

      sleep 0.1
    end

    puts "\n\nFixed #{fixed_count} songs."
  end

  desc 'Fix songs updated in a time range. Usage: rake data_repair:fix_range["2024-12-30 00:00","2024-12-31 23:59"]'
  task :fix_range, %i[start_time end_time] => :environment do |_t, args|
    start_time = Time.zone.parse(args[:start_time])
    end_time = Time.zone.parse(args[:end_time])

    abort 'Please provide start and end times' if start_time.blank? || end_time.blank?

    songs = Song.where.not(id_on_spotify: nil).where(updated_at: start_time..end_time)
    puts "Fixing #{songs.count} songs updated between #{start_time} and #{end_time}..."
    puts '=' * 80

    fixed_count = 0

    songs.find_each.with_index do |song, index|
      print "\rProcessing #{index + 1}/#{songs.count}..."

      result = fetch_spotify_data(song.id_on_spotify)
      next if result.blank?

      mismatch = detect_mismatch(song, result)
      next if mismatch.blank?

      fix_song(song, result, mismatch)
      fixed_count += 1

      sleep 0.1
    end

    puts "\n\nFixed #{fixed_count} songs."
  end

  desc 'Fix a specific song by ID. Usage: rake data_repair:fix_song[123]'
  task :fix_song, [:song_id] => :environment do |_t, args|
    song_id = args[:song_id]
    abort 'Please provide a song ID: rake data_repair:fix_song[123]' if song_id.blank?

    song = Song.includes(:artists).find_by(id: song_id)
    abort "Song with ID #{song_id} not found" if song.blank?
    abort 'Song has no Spotify ID' if song.id_on_spotify.blank?

    puts "Checking song: #{song.title} (ID: #{song.id})"
    puts "Current ISRC: #{song.isrc}"
    puts "Current artists: #{song.artists.map(&:name).join(', ')}"
    puts "Spotify ID: #{song.id_on_spotify}"
    puts '-' * 40

    result = fetch_spotify_data(song.id_on_spotify)
    abort 'Could not fetch Spotify data' if result.blank?

    puts "Spotify title: #{result[:title]}"
    puts "Spotify ISRC: #{result[:isrc]}"
    puts "Spotify artists: #{result[:artists].map { |a| a['name'] }.join(', ')}"

    mismatch = detect_mismatch(song, result)

    if mismatch.blank?
      puts "\nNo mismatches found. Song data is correct."
    else
      puts "\nMismatches found:"
      mismatch[:issues].each { |issue| puts "  - #{issue}" }

      print "\nFix this song? (y/n): "
      if $stdin.gets.chomp.downcase == 'y'
        fix_song(song, result, mismatch)
        song.reload
        puts "\nAfter fix:"
        puts "Title: #{song.title}"
        puts "ISRC: #{song.isrc}"
        puts "Artists: #{song.artists.map(&:name).join(', ')}"
      else
        puts 'Skipped.'
      end
    end
  end

  desc 'Find songs with duplicate ISRCs (potential corruption indicator)'
  task find_duplicate_isrcs: :environment do
    puts 'Finding songs with duplicate ISRCs...'
    puts '=' * 80

    duplicates = Song.where.not(isrc: [nil, ''])
                     .group(:isrc)
                     .having('COUNT(*) > 1')
                     .count

    if duplicates.empty?
      puts 'No duplicate ISRCs found.'
    else
      puts "Found #{duplicates.count} ISRCs with multiple songs:\n\n"

      duplicates.each do |isrc, count|
        puts "ISRC: #{isrc} (#{count} songs)"
        songs = Song.includes(:artists).where(isrc: isrc)
        songs.each do |song|
          puts "  ID: #{song.id} | Title: #{song.title} | Artists: #{song.artists.map(&:name).join(', ')}"
          puts "    Spotify ID: #{song.id_on_spotify} | Played: #{song.air_plays.count}"
        end
        puts
      end
    end
  end

  desc 'Find songs where Spotify ID might be wrong by cross-referencing ISRC'
  task find_wrong_spotify_ids: :environment do
    puts 'Finding songs where Spotify ID might be wrong...'
    puts '=' * 80

    wrong_ids = []

    Song.where.not(id_on_spotify: nil).where.not(isrc: [nil, '']).find_each.with_index do |song, index|
      print "\rChecking #{index + 1}..."

      # Fetch the track from Spotify using the stored ID
      result = fetch_spotify_data(song.id_on_spotify)
      next if result.blank?

      # If Spotify's ISRC for this track doesn't match our stored ISRC,
      # and our ISRC is valid, then the Spotify ID might be wrong
      if result[:isrc].present? && song.isrc.present? && result[:isrc].upcase != song.isrc.upcase
        wrong_ids << {
          song: song,
          db_isrc: song.isrc,
          spotify_isrc: result[:isrc],
          spotify_title: result[:title]
        }
      end

      sleep 0.1
    end

    puts "\n\n"

    if wrong_ids.empty?
      puts 'No songs with potentially wrong Spotify IDs found.'
    else
      puts "Found #{wrong_ids.count} songs with potentially wrong Spotify IDs:\n\n"

      wrong_ids.each do |item|
        song = item[:song]
        puts "Song ID: #{song.id}"
        puts "  DB Title: #{song.title}"
        puts "  DB ISRC: #{item[:db_isrc]}"
        puts "  Spotify ID: #{song.id_on_spotify}"
        puts "  Spotify says ISRC: #{item[:spotify_isrc]}"
        puts "  Spotify says title: #{item[:spotify_title]}"
        puts
      end
    end
  end

  desc 'Re-match songs using ISRC when Spotify ID seems wrong. Usage: rake data_repair:rematch_by_isrc[100]'
  task :rematch_by_isrc, [:limit] => :environment do |_t, args|
    limit = (args[:limit] || 100).to_i
    puts "Re-matching up to #{limit} songs using ISRC..."
    puts '=' * 80

    fixed_count = 0

    Song.where.not(id_on_spotify: nil).where.not(isrc: [nil, '']).limit(limit).find_each.with_index do |song, index|
      print "\rChecking #{index + 1}..."

      # Fetch the track from Spotify using the stored ID
      current_result = fetch_spotify_data(song.id_on_spotify)
      next if current_result.blank?

      # Check if ISRC matches
      next if current_result[:isrc].blank? || song.isrc.blank?
      next if current_result[:isrc].upcase == song.isrc.upcase

      # ISRC doesn't match - try to find the correct track by searching with ISRC
      correct_result = search_spotify_by_isrc(song.isrc)
      next if correct_result.blank?

      puts "\n  Song ID #{song.id}: Fixing Spotify ID"
      puts "    Old: #{song.id_on_spotify} (#{current_result[:title]})"
      puts "    New: #{correct_result[:id]} (#{correct_result[:title]})"

      # Update with correct Spotify data
      song.update_columns(
        id_on_spotify: correct_result[:id],
        spotify_song_url: correct_result[:spotify_url],
        spotify_artwork_url: correct_result[:artwork_url],
        spotify_preview_url: correct_result[:preview_url],
        title: correct_result[:title]
      )

      update_song_artists(song, correct_result[:artists])
      song.send(:update_search_text)

      fixed_count += 1
      sleep 0.2
    end

    puts "\n\nFixed #{fixed_count} songs."
  end

  desc 'Find songs where title might be swapped with artist name'
  task find_swapped_titles: :environment do
    puts 'Finding songs where title might be swapped with artist...'
    puts '=' * 80

    Song.includes(:artists).where.not(id_on_spotify: nil).find_each do |song|
      # Check if the title contains what looks like an artist name pattern
      # and artist name contains what looks like a song title
      artist_names = song.artists.map(&:name)

      # Simple heuristic: if title matches any artist name, it might be swapped
      if artist_names.any? { |name| song.title&.downcase&.include?(name&.downcase) && name&.length.to_i > 3 }
        puts "Potential swap - Song ID: #{song.id}"
        puts "  Title: #{song.title}"
        puts "  Artists: #{artist_names.join(', ')}"
        puts "  Spotify ID: #{song.id_on_spotify}"
        puts
      end
    end
  end

  # Helper methods
  def search_spotify_by_isrc(isrc)
    # Search Spotify for a track with this ISRC
    search_url = URI("https://api.spotify.com/v1/search?q=isrc:#{isrc}&type=track&limit=1")
    response = Spotify::Base.new.send(:make_request, search_url)
    return nil if response.blank?

    track = response.dig('tracks', 'items', 0)
    return nil if track.blank?

    {
      id: track['id'],
      title: track['name'],
      isrc: track.dig('external_ids', 'isrc'),
      spotify_url: track.dig('external_urls', 'spotify'),
      artwork_url: track.dig('album', 'images', 0, 'url'),
      preview_url: track['preview_url'],
      artists: track['artists'] || []
    }
  rescue StandardError => e
    puts "\nError searching Spotify by ISRC #{isrc}: #{e.message}"
    nil
  end

  def fetch_spotify_data(id_on_spotify)
    response = Spotify::TrackFinder::FindById.new(id_on_spotify: id_on_spotify).execute
    return nil if response.blank?

    {
      title: response['name'],
      isrc: response.dig('external_ids', 'isrc'),
      spotify_url: response.dig('external_urls', 'spotify'),
      artwork_url: response.dig('album', 'images', 0, 'url'),
      preview_url: response['preview_url'],
      artists: response['artists'] || [],
      album_artists: response.dig('album', 'artists') || []
    }
  rescue StandardError => e
    puts "\nError fetching Spotify data for #{id_on_spotify}: #{e.message}"
    nil
  end

  def detect_mismatch(song, spotify_data)
    issues = []

    # Check title mismatch (case-insensitive, ignoring minor differences)
    if spotify_data[:title].present? && song.title.present?
      db_title = normalize_title(song.title)
      spotify_title = normalize_title(spotify_data[:title])
      if db_title != spotify_title && !similar_titles?(db_title, spotify_title)
        issues << "Title mismatch: DB='#{song.title}' vs Spotify='#{spotify_data[:title]}'"
      end
    end

    # Check ISRC mismatch
    if spotify_data[:isrc].present? && song.isrc.present? && (song.isrc.upcase != spotify_data[:isrc].upcase)
      issues << "ISRC mismatch: DB='#{song.isrc}' vs Spotify='#{spotify_data[:isrc]}'"
    end

    # Check if song has ISRC but Spotify says different, even if our ISRC is blank
    issues << "Missing ISRC: Spotify has '#{spotify_data[:isrc]}'" if spotify_data[:isrc].present? && song.isrc.blank?

    # Check artist mismatch
    db_artist_names = song.artists.map { |a| normalize_artist(a.name) }.sort
    spotify_artist_names = spotify_data[:artists].map { |a| normalize_artist(a['name']) }.sort

    if db_artist_names != spotify_artist_names && !artists_similar_enough?(db_artist_names, spotify_artist_names)
      issues << "Artist mismatch: DB='#{song.artists.map(&:name).join(', ')}' vs Spotify='#{spotify_data[:artists].map { |a| a['name'] }.join(', ')}'"
    end

    return nil if issues.empty?

    {
      song: song,
      spotify_data: spotify_data,
      issues: issues
    }
  end

  def fix_song(song, spotify_data, mismatch)
    updates = {}

    # Update title if mismatched
    updates[:title] = spotify_data[:title] if mismatch[:issues].any? { |i| i.include?('Title mismatch') }

    # Update ISRC if mismatched or missing
    updates[:isrc] = spotify_data[:isrc] if mismatch[:issues].any? { |i| i.include?('ISRC') }

    # Update Spotify URLs
    updates[:spotify_song_url] = spotify_data[:spotify_url] if spotify_data[:spotify_url].present?
    updates[:spotify_artwork_url] = spotify_data[:artwork_url] if spotify_data[:artwork_url].present?
    updates[:spotify_preview_url] = spotify_data[:preview_url] if spotify_data[:preview_url].present?

    # Apply updates using update_columns to avoid callbacks
    song.update_columns(updates.compact) if updates.present? # rubocop:disable Rails/SkipsModelValidations

    # Update artists if mismatched
    update_song_artists(song, spotify_data[:artists]) if mismatch[:issues].any? { |i| i.include?('Artist mismatch') }

    # Update search_text
    song.send(:update_search_text)

    puts "\n  Fixed song ID #{song.id}: #{mismatch[:issues].join(', ')}"
  end

  def update_song_artists(song, spotify_artists)
    return if spotify_artists.blank?

    artists = spotify_artists.map do |artist_data|
      Artist.find_or_create_by(id_on_spotify: artist_data['id']) do |artist|
        artist.name = artist_data['name']
      end
    end

    song.artists = artists
  end

  def normalize_title(title)
    title.to_s.downcase.gsub(/[^\w\s]/, '').gsub(/\s+/, ' ').strip
  end

  def normalize_artist(name)
    name.to_s.downcase.gsub(/[^\w\s]/, '').gsub(/\s+/, ' ').strip
  end

  def similar_titles?(title1, title2)
    # Consider titles similar if one contains the other (for feat. variations)
    title1.include?(title2) || title2.include?(title1) ||
      levenshtein_similar?(title1, title2, 0.85)
  end

  def artists_similar_enough?(db_artists, spotify_artists)
    # If at least one artist matches, consider it close enough for minor variations
    (db_artists & spotify_artists).any?
  end

  def levenshtein_similar?(str1, str2, threshold)
    return true if str1 == str2

    distance = levenshtein_distance(str1, str2)
    max_length = [str1.length, str2.length].max
    return true if max_length.zero?

    similarity = 1.0 - (distance.to_f / max_length)
    similarity >= threshold
  end

  def levenshtein_distance(str1, str2)
    m = str1.length
    n = str2.length
    return m if n.zero?
    return n if m.zero?

    d = Array.new(m + 1) { Array.new(n + 1) }

    (0..m).each { |i| d[i][0] = i }
    (0..n).each { |j| d[0][j] = j }

    (1..n).each do |j|
      (1..m).each do |i|
        cost = str1[i - 1] == str2[j - 1] ? 0 : 1
        d[i][j] = [d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + cost].min
      end
    end

    d[m][n]
  end

  def print_mismatch_report(mismatches)
    if mismatches.empty?
      puts 'No mismatches found. All verified songs match Spotify data.'
      return
    end

    puts "Found #{mismatches.count} songs with mismatches:\n\n"

    mismatches.each do |mismatch|
      song = mismatch[:song]
      puts "Song ID: #{song.id}"
      puts "  DB Title: #{song.title}"
      puts "  DB ISRC: #{song.isrc}"
      puts "  DB Artists: #{song.artists.map(&:name).join(', ')}"
      puts "  Spotify ID: #{song.id_on_spotify}"
      puts '  Issues:'
      mismatch[:issues].each { |issue| puts "    - #{issue}" }
      puts
    end

    puts '-' * 80
    puts "To fix these songs, run: rake data_repair:fix_songs[#{mismatches.count}]"
  end
end
