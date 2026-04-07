# frozen_string_literal: true

# Fuzzy matching thresholds (same as AirPlay model)
FUZZY_TITLE_SIMILARITY_THRESHOLD = 70
FUZZY_ARTIST_SIMILARITY_THRESHOLD = 80

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

  desc 'Merge songs with the same ISRC. Keeps the song with most air_plays, merges others into it.'
  task merge_duplicate_isrcs: :environment do
    puts 'Merging songs with duplicate ISRCs...'
    puts '=' * 80

    duplicate_isrcs = Song.where.not(isrc: [nil, ''])
                        .group(:isrc)
                        .having('COUNT(*) > 1')
                        .pluck(:isrc)

    if duplicate_isrcs.empty?
      puts 'No duplicate ISRCs found. Nothing to merge.'
      return
    end

    puts "Found #{duplicate_isrcs.count} ISRCs with multiple songs\n\n"

    merged_count = 0
    deleted_count = 0

    duplicate_isrcs.each do |isrc|
      songs = Song.includes(:artists, :air_plays).where(isrc: isrc).to_a

      # Keep the song with the most air_plays, or the oldest if tied
      keeper = songs.max_by { |s| [s.air_plays.count, -s.id] }
      duplicates = songs - [keeper]

      puts "ISRC: #{isrc}"
      puts "  Keeping: ID #{keeper.id} | #{keeper.title} | #{keeper.air_plays.count} air_plays"

      duplicates.each do |duplicate|
        puts "  Merging: ID #{duplicate.id} | #{duplicate.title} | #{duplicate.air_plays.count} air_plays"

        merge_song_into(duplicate, keeper)
        deleted_count += 1
      end

      merged_count += 1
      puts
    end

    puts '=' * 80
    puts "Merged #{merged_count} ISRC groups, deleted #{deleted_count} duplicate songs."
  end

  desc 'Dry run: Show what would be merged without making changes'
  task merge_duplicate_isrcs_dry_run: :environment do
    puts 'DRY RUN: Showing what would be merged...'
    puts '=' * 80

    duplicate_isrcs = Song.where.not(isrc: [nil, ''])
                        .group(:isrc)
                        .having('COUNT(*) > 1')
                        .pluck(:isrc)

    if duplicate_isrcs.empty?
      puts 'No duplicate ISRCs found. Nothing to merge.'
      return
    end

    puts "Found #{duplicate_isrcs.count} ISRCs with multiple songs\n\n"

    total_air_plays_to_merge = 0
    total_songs_to_delete = 0

    duplicate_isrcs.each do |isrc|
      songs = Song.includes(:artists, :air_plays).where(isrc: isrc).to_a

      keeper = songs.max_by { |s| [s.air_plays.count, -s.id] }
      duplicates = songs - [keeper]

      puts "ISRC: #{isrc}"
      puts "  KEEP: ID #{keeper.id} | #{keeper.title} | Artists: #{keeper.artists.map(&:name).join(', ')}"
      puts "        Spotify: #{keeper.id_on_spotify} | Air plays: #{keeper.air_plays.count}"

      duplicates.each do |duplicate|
        air_play_count = duplicate.air_plays.count
        puts "  DELETE: ID #{duplicate.id} | #{duplicate.title} | Artists: #{duplicate.artists.map(&:name).join(', ')}"
        puts "          Spotify: #{duplicate.id_on_spotify} | Air plays: #{air_play_count}"
        total_air_plays_to_merge += air_play_count
        total_songs_to_delete += 1
      end
      puts
    end

    puts '=' * 80
    puts "Would merge #{duplicate_isrcs.count} ISRC groups"
    puts "Would delete #{total_songs_to_delete} duplicate songs"
    puts "Would reassign #{total_air_plays_to_merge} air_plays"
    puts "\nRun 'rake data_repair:merge_duplicate_isrcs' to perform the merge."
  end

  def merge_song_into(source, target)
    ActiveRecord::Base.transaction do
      merge_air_plays(source, target)
      merge_radio_station_songs(source, target)

      # Merge chart_positions
      source.chart_positions.update_all(positianable_id: target.id) # rubocop:disable Rails/SkipsModelValidations

      # Reassign song_import_logs
      source.song_import_logs.update_all(song_id: target.id) # rubocop:disable Rails/SkipsModelValidations

      # Merge music_profile if target doesn't have one
      source.music_profile.update!(song_id: target.id) if source.music_profile.present? && target.music_profile.blank?

      # Enrich target with any missing data from source
      enrich_target_from_source(target, source)

      # Delete the source song
      source.reload.destroy!
    end
  end

  def merge_air_plays(source, target)
    source.air_plays.find_each do |air_play|
      existing = AirPlay.find_by(
        song_id: target.id,
        radio_station_id: air_play.radio_station_id,
        broadcasted_at: air_play.broadcasted_at
      )

      if existing
        air_play.destroy
      else
        air_play.update!(song_id: target.id)
      end
    end
  end

  def merge_radio_station_songs(source, target)
    source.radio_station_songs.find_each do |rss|
      existing = RadioStationSong.find_by(song_id: target.id, radio_station_id: rss.radio_station_id)

      if existing
        update_first_broadcasted_at(existing, rss)
        rss.destroy
      else
        rss.update!(song_id: target.id)
      end
    end
  end

  def update_first_broadcasted_at(existing, source_rss)
    return if source_rss.first_broadcasted_at.blank?
    return unless existing.first_broadcasted_at.blank? || source_rss.first_broadcasted_at < existing.first_broadcasted_at

    existing.update!(first_broadcasted_at: source_rss.first_broadcasted_at)
  end

  def enrich_target_from_source(target, source) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    updates = {}

    # Copy over any missing IDs/URLs from source
    updates[:id_on_spotify] = source.id_on_spotify if target.id_on_spotify.blank? && source.id_on_spotify.present?
    updates[:id_on_youtube] = source.id_on_youtube if target.id_on_youtube.blank? && source.id_on_youtube.present?
    updates[:id_on_deezer] = source.id_on_deezer if target.id_on_deezer.blank? && source.id_on_deezer.present?
    updates[:id_on_itunes] = source.id_on_itunes if target.id_on_itunes.blank? && source.id_on_itunes.present?

    updates[:spotify_song_url] = source.spotify_song_url if target.spotify_song_url.blank? && source.spotify_song_url.present?
    updates[:spotify_artwork_url] = source.spotify_artwork_url if target.spotify_artwork_url.blank? && source.spotify_artwork_url.present?
    updates[:spotify_preview_url] = source.spotify_preview_url if target.spotify_preview_url.blank? && source.spotify_preview_url.present?

    updates[:deezer_song_url] = source.deezer_song_url if target.deezer_song_url.blank? && source.deezer_song_url.present?
    updates[:deezer_artwork_url] = source.deezer_artwork_url if target.deezer_artwork_url.blank? && source.deezer_artwork_url.present?
    updates[:deezer_preview_url] = source.deezer_preview_url if target.deezer_preview_url.blank? && source.deezer_preview_url.present?

    updates[:itunes_song_url] = source.itunes_song_url if target.itunes_song_url.blank? && source.itunes_song_url.present?
    updates[:itunes_artwork_url] = source.itunes_artwork_url if target.itunes_artwork_url.blank? && source.itunes_artwork_url.present?
    updates[:itunes_preview_url] = source.itunes_preview_url if target.itunes_preview_url.blank? && source.itunes_preview_url.present?

    updates[:release_date] = source.release_date if target.release_date.blank? && source.release_date.present?
    updates[:release_date_precision] = source.release_date_precision if target.release_date_precision.blank? && source.release_date_precision.present?

    target.update!(updates) if updates.present?
  end

  desc 'Find songs that might be duplicates based on fuzzy title/artist matching'
  task find_fuzzy_duplicates: :environment do
    puts 'Finding potential duplicate songs using fuzzy matching...'
    puts '=' * 80

    duplicates = find_fuzzy_duplicate_groups
    print_fuzzy_duplicate_report(duplicates)
  end

  desc 'Dry run: Show what would be merged using fuzzy matching'
  task merge_fuzzy_duplicates_dry_run: :environment do
    puts 'DRY RUN: Showing what would be merged using fuzzy matching...'
    puts '=' * 80

    duplicates = find_fuzzy_duplicate_groups

    if duplicates.empty?
      puts 'No fuzzy duplicates found. Nothing to merge.'
      return
    end

    puts "Found #{duplicates.count} potential duplicate groups\n\n"

    total_air_plays_to_merge = 0
    total_songs_to_delete = 0

    duplicates.each do |group|
      keeper = group[:keeper]
      dupes = group[:duplicates]

      puts "Group: #{group[:normalized_key]}"
      puts "  KEEP: ID #{keeper.id} | #{keeper.title} | Artists: #{keeper.artists.map(&:name).join(', ')}"
      puts "        Spotify: #{keeper.id_on_spotify || 'none'} | ISRC: #{keeper.isrc || 'none'} | Air plays: #{keeper.air_plays.count}"

      dupes.each do |duplicate|
        air_play_count = duplicate.air_plays.count
        puts "  DELETE: ID #{duplicate.id} | #{duplicate.title} | Artists: #{duplicate.artists.map(&:name).join(', ')}"
        puts "          Spotify: #{duplicate.id_on_spotify || 'none'} | ISRC: #{duplicate.isrc || 'none'} | Air plays: #{air_play_count}"
        total_air_plays_to_merge += air_play_count
        total_songs_to_delete += 1
      end
      puts
    end

    puts '=' * 80
    puts "Would merge #{duplicates.count} duplicate groups"
    puts "Would delete #{total_songs_to_delete} duplicate songs"
    puts "Would reassign #{total_air_plays_to_merge} air_plays"
    puts "\nRun 'rake data_repair:merge_fuzzy_duplicates' to perform the merge."
  end

  desc 'Merge songs that are duplicates based on fuzzy title/artist matching'
  task merge_fuzzy_duplicates: :environment do
    puts 'Merging songs with fuzzy matching...'
    puts '=' * 80

    duplicates = find_fuzzy_duplicate_groups

    if duplicates.empty?
      puts 'No fuzzy duplicates found. Nothing to merge.'
      return
    end

    puts "Found #{duplicates.count} duplicate groups to merge\n\n"

    merged_count = 0
    deleted_count = 0

    duplicates.each do |group|
      keeper = group[:keeper]
      dupes = group[:duplicates]

      puts "Group: #{group[:normalized_key]}"
      puts "  Keeping: ID #{keeper.id} | #{keeper.title} | #{keeper.air_plays.count} air_plays"

      dupes.each do |duplicate|
        puts "  Merging: ID #{duplicate.id} | #{duplicate.title} | #{duplicate.air_plays.count} air_plays"

        merge_song_into(duplicate, keeper)
        deleted_count += 1
      end

      merged_count += 1
      puts
    end

    puts '=' * 80
    puts "Merged #{merged_count} duplicate groups, deleted #{deleted_count} duplicate songs."
  end

  def find_fuzzy_duplicate_groups # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    # Phase 1: Build groups using lightweight data (only IDs and strings)
    # This avoids loading all songs with associations into memory at once
    groups = {} # key => array of {id:, title:, artists:, has_spotify:}
    processed = 0

    Song.includes(:artists).select(:id, :title, :id_on_spotify).find_each do |song|
      processed += 1
      print "\rPhase 1: Processing song #{processed}..." if (processed % 1000).zero?

      title = song.title.to_s.downcase.strip
      artists = song.artists.map(&:name).sort.join(' ').downcase.strip
      next if title.blank? || artists.blank?

      song_data = {
        id: song.id,
        title: title,
        original_title: song.title,
        artists: artists,
        has_spotify: song.id_on_spotify.present?
      }

      # Find if this song matches any existing group
      matched_group = nil
      groups.each do |key, group|
        ref = group.first
        ref_title = ref[:title]
        ref_artists = ref[:artists]

        title_similarity = (JaroWinkler.similarity(title, ref_title) * 100).to_i
        artist_similarity = (JaroWinkler.similarity(artists, ref_artists) * 100).to_i

        if title_similarity >= FUZZY_TITLE_SIMILARITY_THRESHOLD && artist_similarity >= FUZZY_ARTIST_SIMILARITY_THRESHOLD
          matched_group = key
          break
        end
      end

      if matched_group
        groups[matched_group] << song_data
      else
        normalized_key = "#{title} - #{artists}"
        groups[normalized_key] = [song_data]
      end
    end

    puts "\rPhase 1: Processed #{processed} songs, found #{groups.count} groups"

    # Filter to only groups with more than one song
    duplicate_groups = groups.select { |_key, song_list| song_list.size > 1 }
    puts "Phase 2: Found #{duplicate_groups.count} duplicate groups"

    return [] if duplicate_groups.empty?

    # Phase 2: Load full song objects only for duplicates, with air_play counts
    duplicate_song_ids = duplicate_groups.values.flatten.map { |s| s[:id] }
    air_play_counts = AirPlay.where(song_id: duplicate_song_ids).group(:song_id).count
    songs_by_id = Song.includes(:artists, :air_plays).where(id: duplicate_song_ids).index_by(&:id)

    # Transform into structured format with keeper selection
    duplicate_groups.map do |key, song_data_list|
      songs_in_group = song_data_list.map { |data| songs_by_id[data[:id]] }.compact

      # Prefer song with Spotify ID, then most air_plays, then oldest (lowest ID)
      sorted = songs_in_group.sort_by do |s|
        [
          s.id_on_spotify.present? ? 0 : 1,
          -(air_play_counts[s.id] || 0),
          s.id
        ]
      end

      keeper = sorted.first
      duplicates = sorted[1..]

      {
        normalized_key: key,
        keeper: keeper,
        duplicates: duplicates
      }
    end
  end

  def print_fuzzy_duplicate_report(duplicates)
    if duplicates.empty?
      puts 'No fuzzy duplicates found.'
      return
    end

    puts "Found #{duplicates.count} potential duplicate groups:\n\n"

    duplicates.each do |group|
      puts "Group: #{group[:normalized_key]}"
      all_songs = [group[:keeper]] + group[:duplicates]
      all_songs.each do |song|
        marker = song == group[:keeper] ? '[KEEPER]' : '[DUPLICATE]'
        puts "  #{marker} ID: #{song.id} | Title: #{song.title}"
        puts "           Artists: #{song.artists.map(&:name).join(', ')}"
        puts "           Spotify: #{song.id_on_spotify || 'none'} | ISRC: #{song.isrc || 'none'}"
        puts "           Air plays: #{song.air_plays.count}"
      end
      puts
    end

    puts "\nRun 'rake data_repair:merge_fuzzy_duplicates_dry_run' to see merge plan."
    puts "Run 'rake data_repair:merge_fuzzy_duplicates' to perform the merge."
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
      song.update_columns( # rubocop:disable Rails/SkipsModelValidations
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

  desc 'Destroy artists that have no songs and no air plays. Usage: rake data_repair:cleanup_orphaned_artists'
  task cleanup_orphaned_artists: :environment do
    puts 'Finding orphaned artists (no songs, no air plays)...'
    puts '=' * 80

    orphaned_ids = orphaned_artist_ids
    total = orphaned_ids.size

    if total.zero?
      puts 'No orphaned artists found.'
      next
    end

    puts "Found #{total} orphaned artists to destroy"

    # Bulk-delete dependent records and artists in batches
    destroyed_count = 0
    orphaned_ids.each_slice(1000) do |batch_ids|
      ArtistsSong.where(artist_id: batch_ids).delete_all
      ChartPosition.where(positianable_type: 'Artist', positianable_id: batch_ids).delete_all
      destroyed_count += Artist.where(id: batch_ids).delete_all
      puts "  Destroyed #{destroyed_count}/#{total}..."
    end

    puts "\n#{'=' * 80}"
    puts "Destroyed #{destroyed_count} orphaned artists."
  end

  desc 'Dry run: Show orphaned artists that would be destroyed'
  task cleanup_orphaned_artists_dry_run: :environment do
    puts 'DRY RUN: Finding orphaned artists (no songs, no air plays)...'
    puts '=' * 80

    orphaned_ids = orphaned_artist_ids
    total = orphaned_ids.size

    if total.zero?
      puts 'No orphaned artists found.'
      next
    end

    puts "Found #{total} orphaned artists\n\n"

    puts 'Sample (first 20):'
    Artist.where(id: orphaned_ids.first(20)).find_each do |artist|
      puts "  ID #{artist.id} | #{artist.name} | Spotify: #{artist.id_on_spotify || 'none'}"
    end
    puts "  ... and #{total - 20} more" if total > 20

    puts "\n#{'=' * 80}"
    puts "Would destroy #{total} orphaned artists."
    puts "\nRun 'rake data_repair:cleanup_orphaned_artists' to perform the cleanup."
  end

  desc 'Destroy orphaned artists_songs records pointing to non-existent songs or artists'
  task cleanup_orphaned_artists_songs: :environment do
    puts 'Finding orphaned artists_songs records...'
    puts '=' * 80

    orphaned_by_song_count = ActiveRecord::Base.connection.delete(<<~SQL.squish)
      DELETE FROM artists_songs
      WHERE NOT EXISTS (SELECT 1 FROM songs WHERE songs.id = artists_songs.song_id)
    SQL

    orphaned_by_artist_count = ActiveRecord::Base.connection.delete(<<~SQL.squish)
      DELETE FROM artists_songs
      WHERE NOT EXISTS (SELECT 1 FROM artists WHERE artists.id = artists_songs.artist_id)
    SQL

    puts "Deleted #{orphaned_by_song_count} records with non-existent songs"
    puts "Deleted #{orphaned_by_artist_count} records with non-existent artists"

    total = orphaned_by_song_count + orphaned_by_artist_count
    if total.zero?
      puts 'No orphaned artists_songs records found.'
    else
      puts "\nDeleted #{total} orphaned records total."
    end
  end

  desc 'Dry run: Show orphaned artists_songs records'
  task cleanup_orphaned_artists_songs_dry_run: :environment do
    puts 'DRY RUN: Finding orphaned artists_songs records...'
    puts '=' * 80

    orphaned_by_song = ArtistsSong.joins('LEFT JOIN songs ON songs.id = artists_songs.song_id').where(songs: { id: nil })
    orphaned_by_artist = ArtistsSong.joins('LEFT JOIN artists ON artists.id = artists_songs.artist_id').where(artists: { id: nil })

    orphaned_by_song_count = orphaned_by_song.count
    orphaned_by_artist_count = orphaned_by_artist.count

    puts "Found #{orphaned_by_song_count} records with non-existent songs"
    puts "Found #{orphaned_by_artist_count} records with non-existent artists"

    if orphaned_by_song_count.positive?
      puts "\nSample orphaned-by-song (first 20):"
      orphaned_by_song.includes(:artist).limit(20).each do |record|
        puts "  artist_id: #{record.artist_id} (#{record.artist&.name || 'MISSING'}) → song_id: #{record.song_id} (MISSING)"
      end
    end

    if orphaned_by_artist_count.positive?
      puts "\nSample orphaned-by-artist (first 20):"
      orphaned_by_artist.includes(:song).limit(20).each do |record|
        puts "  artist_id: #{record.artist_id} (MISSING) → song_id: #{record.song_id} (#{record.song&.title || 'MISSING'})"
      end
    end

    puts "\n#{'=' * 80}"
    puts "Would delete #{orphaned_by_song_count + orphaned_by_artist_count} orphaned artists_songs records."
    puts "\nRun 'rake data_repair:cleanup_orphaned_artists_songs' to perform the cleanup."
  end

  desc 'Find duplicate artists by Spotify ID and fuzzy name matching. Usage: rake data_repair:find_duplicate_artists'
  task find_duplicate_artists: :environment do
    puts 'Finding duplicate artists...'
    puts '=' * 80

    merger = DuplicateArtistMerger.new
    groups = merger.find_duplicates
    print_duplicate_artist_report(groups)
  end

  desc 'Dry run: Show what artist merges would happen. Usage: rake data_repair:merge_duplicate_artists_dry_run'
  task merge_duplicate_artists_dry_run: :environment do
    puts 'DRY RUN: Finding duplicate artists to merge...'
    puts '=' * 80

    merger = DuplicateArtistMerger.new
    groups = merger.find_duplicates

    if groups.empty?
      puts 'No duplicate artists found.'
      next
    end

    puts "Found #{groups.count} duplicate groups\n\n"

    total_to_delete = 0

    groups.each do |group|
      puts "  KEEP: ID #{group[:keeper].id} | #{group[:keeper].name} | " \
           "Spotify: #{group[:keeper].id_on_spotify || 'none'} | Songs: #{group[:keeper].songs.count}"
      group[:duplicates].each do |dup_artist|
        puts "  DELETE: ID #{dup_artist.id} | #{dup_artist.name} | " \
             "Spotify: #{dup_artist.id_on_spotify || 'none'} | Songs: #{dup_artist.songs.count}"
        total_to_delete += 1
      end
      puts
    end

    puts '=' * 80
    puts "Would merge #{groups.count} duplicate groups, removing #{total_to_delete} duplicate artists."
    puts "\nRun 'rake data_repair:merge_duplicate_artists' to perform the merge."
  end

  desc 'Merge duplicate artists. Usage: rake data_repair:merge_duplicate_artists'
  task merge_duplicate_artists: :environment do
    puts 'Merging duplicate artists...'
    puts '=' * 80

    merger = DuplicateArtistMerger.new
    result = merger.merge_all

    if result[:merged].zero?
      puts 'No duplicate artists found.'
    else
      puts "Merged #{result[:merged]} duplicate groups, removed #{result[:deleted]} duplicate artists."
    end
  end

  def print_duplicate_artist_report(groups)
    if groups.empty?
      puts 'No duplicate artists found.'
      return
    end

    puts "Found #{groups.count} duplicate artist groups:\n\n"

    groups.each do |group|
      puts "Group (#{group[:reason]}):"
      all = [group[:keeper]] + group[:duplicates]
      all.each do |artist|
        marker = artist == group[:keeper] ? '[KEEPER]' : '[DUPLICATE]'
        puts "  #{marker} ID: #{artist.id} | #{artist.name} | Spotify: #{artist.id_on_spotify || 'none'} | Songs: #{artist.songs.count}"
      end
      puts
    end

    puts "\nRun 'rake data_repair:merge_duplicate_artists_dry_run' to see merge plan."
    puts "Run 'rake data_repair:merge_duplicate_artists' to perform the merge."
  end

  desc 'Find duplicate songs by Spotify ID and fuzzy title matching. Usage: rake data_repair:find_duplicate_songs'
  task find_duplicate_songs: :environment do
    puts 'Finding duplicate songs...'
    puts '=' * 80

    merger = DuplicateSongMerger.new
    groups = merger.find_duplicates
    print_duplicate_song_report(groups)
  end

  desc 'Dry run: Show what song merges would happen. Usage: rake data_repair:merge_duplicate_songs_dry_run'
  task merge_duplicate_songs_dry_run: :environment do
    puts 'DRY RUN: Finding duplicate songs to merge...'
    puts '=' * 80

    merger = DuplicateSongMerger.new
    groups = merger.find_duplicates

    if groups.empty?
      puts 'No duplicate songs found.'
      next
    end

    puts "Found #{groups.count} duplicate groups\n\n"

    total_to_delete = 0

    groups.each do |group|
      puts "  KEEP: ID #{group[:keeper].id} | #{group[:keeper].title} | " \
           "Artists: #{group[:keeper].artists.map(&:name).join(', ')} | " \
           "Spotify: #{group[:keeper].id_on_spotify || 'none'} | Air plays: #{group[:keeper].air_plays.count}"
      group[:duplicates].each do |dup_song|
        puts "  DELETE: ID #{dup_song.id} | #{dup_song.title} | " \
             "Spotify: #{dup_song.id_on_spotify || 'none'} | Air plays: #{dup_song.air_plays.count}"
        total_to_delete += 1
      end
      puts
    end

    puts '=' * 80
    puts "Would merge #{groups.count} duplicate groups, removing #{total_to_delete} duplicate songs."
    puts "\nRun 'rake data_repair:merge_duplicate_songs' to perform the merge."
  end

  desc 'Merge duplicate songs. Usage: rake data_repair:merge_duplicate_songs'
  task merge_duplicate_songs: :environment do
    puts 'Merging duplicate songs...'
    puts '=' * 80

    merger = DuplicateSongMerger.new
    result = merger.merge_all

    if result[:merged].zero?
      puts 'No duplicate songs found.'
    else
      puts "Merged #{result[:merged]} duplicate groups, removed #{result[:deleted]} duplicate songs."
    end
  end

  def print_duplicate_song_report(groups)
    if groups.empty?
      puts 'No duplicate songs found.'
      return
    end

    puts "Found #{groups.count} duplicate song groups:\n\n"

    groups.each do |group|
      puts "Group (#{group[:reason]}):"
      all = [group[:keeper]] + group[:duplicates]
      all.each do |song|
        marker = song == group[:keeper] ? '[KEEPER]' : '[DUPLICATE]'
        puts "  #{marker} ID: #{song.id} | #{song.title} | Artists: #{song.artists.map(&:name).join(', ')} | " \
             "Spotify: #{song.id_on_spotify || 'none'} | Air plays: #{song.air_plays.count}"
      end
      puts
    end

    puts "\nRun 'rake data_repair:merge_duplicate_songs_dry_run' to see merge plan."
    puts "Run 'rake data_repair:merge_duplicate_songs' to perform the merge."
  end

  # Helper methods
  def orphaned_artist_ids
    Artist.where(<<~SQL.squish).pluck(:id)
      NOT EXISTS (
        SELECT 1 FROM artists_songs
        INNER JOIN songs ON songs.id = artists_songs.song_id
        WHERE artists_songs.artist_id = artists.id
      )
    SQL
  end

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

  def detect_mismatch(song, spotify_data) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
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

  def fix_song(song, spotify_data, mismatch) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
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

  def levenshtein_distance(str1, str2) # rubocop:disable Metrics/AbcSize
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

  desc 'Split a combined artist into individual artists. Usage: rake data_repair:split_combined_artist[1037]'
  task :split_combined_artist, [:artist_id] => :environment do |_t, args|
    abort 'Please provide an artist ID' if args[:artist_id].blank?

    artist = Artist.find(args[:artist_id])
    puts "Splitting combined artist: '#{artist.name}' (ID: #{artist.id})"
    puts "  Songs: #{artist.songs.count}"
    puts "  Chart positions: #{artist.chart_positions.count}"

    splitter = CombinedArtistSplitter.new(artist)
    individual_artists = splitter.split

    puts "\nSplit into #{individual_artists.size} artists:"
    individual_artists.each do |a|
      puts "  - '#{a.name}' (ID: #{a.id}, songs: #{a.songs.count})"
    end
    puts "\nDone! Combined artist '#{artist.name}' has been removed."
  end

  desc 'Dry run: Show what a combined artist split would do. Usage: rake data_repair:split_combined_artist_dry_run[1037]'
  task :split_combined_artist_dry_run, [:artist_id] => :environment do |_t, args|
    abort 'Please provide an artist ID' if args[:artist_id].blank?

    artist = Artist.find(args[:artist_id])
    regex = Regexp.new(Song::MULTIPLE_ARTIST_REGEX, Regexp::IGNORECASE)
    names = artist.name.split(regex).map(&:strip).reject(&:blank?)

    puts "Combined artist: '#{artist.name}' (ID: #{artist.id})"
    puts "  Songs: #{artist.songs.count}"
    puts "  Chart positions: #{artist.chart_positions.count}"
    puts "\nWould split into:"
    names.each do |name|
      existing = Artist.find_by(name:)
      if existing
        puts "  - '#{name}' (existing, ID: #{existing.id}, songs: #{existing.songs.count})"
      else
        puts "  - '#{name}' (new artist, will be created)"
      end
    end
    puts "\nRun 'rake data_repair:split_combined_artist[#{artist.id}]' to perform the split."
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

  desc 'Confirm draft airplays for recognizer-only stations (no processor). Usage: rake data_repair:confirm_recognizer_drafts'
  task confirm_recognizer_drafts: :environment do
    stations = RadioStation.recognizer_only
    puts "Found #{stations.count} recognizer-only stations: #{stations.pluck(:name).join(', ')}"
    puts '=' * 80

    stations.find_each do |station|
      drafts = AirPlay.draft.where(radio_station: station)
      count = drafts.count
      next if count.zero?

      puts "#{station.name}: confirming #{count} draft airplays..."
      drafts.update_all(status: :confirmed) # rubocop:disable Rails/SkipsModelValidations
      puts '  Done.'
    end

    puts '=' * 80
    puts 'Finished confirming recognizer-only drafts.'
  end

  desc 'Re-create missing airplays for radio_station_songs without airplays. Usage: rake data_repair:recreate_missing_airplays[station_name]'
  task :recreate_missing_airplays, [:station_name] => :environment do |_t, args|
    station_name = args[:station_name]
    if station_name.blank?
      puts 'Usage: rake data_repair:recreate_missing_airplays[station_name]'
      puts 'Example: rake "data_repair:recreate_missing_airplays[Radio Decibel]"'
      next
    end

    station = RadioStation.find_by('name ILIKE ?', "%#{station_name}%")
    if station.blank?
      puts "No radio station found matching '#{station_name}'"
      next
    end

    puts "Found station: #{station.name} (ID: #{station.id})"
    puts '=' * 80

    orphaned = station.radio_station_songs
                 .left_joins(:song)
                 .where.not(song_id: station.air_plays.select(:song_id))
                 .where.not(first_broadcasted_at: nil)
                 .includes(:song)

    count = orphaned.count
    if count.zero?
      puts 'No radio_station_songs without airplays found.'
      next
    end

    puts "Found #{count} radio_station_songs without airplays. Creating airplays..."
    puts '-' * 80

    created = 0
    skipped = 0

    orphaned.find_each do |rss|
      airplay = AirPlay.new(
        radio_station_id: station.id,
        song_id: rss.song_id,
        broadcasted_at: rss.first_broadcasted_at,
        scraper_import: true,
        status: :confirmed
      )

      if airplay.save
        created += 1
        puts "  Created airplay for '#{rss.song&.title}' at #{rss.first_broadcasted_at}"
      else
        skipped += 1
        puts "  Skipped '#{rss.song&.title}': #{airplay.errors.full_messages.join(', ')}"
      end
    end

    puts '=' * 80
    puts "Done. Created: #{created}, Skipped: #{skipped}"
  end

  desc 'Dry run: Show airplays linked to wrong songs via fuzzy mismatch. Usage: rake data_repair:find_mismatched_airplays[1000]'
  task :find_mismatched_airplays, [:limit] => :environment do |_t, args|
    limit = (args[:limit] || 1000).to_i
    puts "Scanning up to #{limit} import logs for mismatched airplays (dry run)..."
    puts '=' * 80

    repair = MismatchedAirplayRepair.new(dry_run: true, limit: limit)
    results = repair.run

    puts '=' * 80
    puts "Checked: #{results[:checked]}, Mismatched: #{results[:mismatched]}"
    puts "Errors: #{results[:errors].count}" if results[:errors].any?
    results[:errors].each { |e| puts "  Log ##{e[:log_id]}: #{e[:error]}" }
  end

  desc 'Fix airplays linked to wrong songs via fuzzy mismatch. Usage: rake data_repair:fix_mismatched_airplays[1000]'
  task :fix_mismatched_airplays, [:limit] => :environment do |_t, args|
    limit = (args[:limit] || 1000).to_i
    puts "Fixing up to #{limit} mismatched airplays..."
    puts '=' * 80

    repair = MismatchedAirplayRepair.new(dry_run: false, limit: limit)
    results = repair.run

    puts '=' * 80
    puts "Checked: #{results[:checked]}, Mismatched: #{results[:mismatched]}, Fixed: #{results[:fixed]}"
    puts "Errors: #{results[:errors].count}" if results[:errors].any?
    results[:errors].each { |e| puts "  Log ##{e[:log_id]}: #{e[:error]}" }
  end

  desc 'Find songs with cross-contaminated ISRCs (ISRCs belonging to different Spotify tracks). ' \
       'Usage: rake data_repair:find_contaminated_isrcs[500]'
  task :find_contaminated_isrcs, [:limit] => :environment do |_t, args|
    limit = (args[:limit] || 500).to_i
    puts "Scanning up to #{limit} songs for ISRC cross-contamination (dry run)..."
    puts '=' * 80

    repair = IsrcCrossContaminationRepair.new(dry_run: true, limit:)
    results = repair.run

    puts "\n#{'=' * 80}"
    puts "Checked: #{results[:checked]}, Contaminated: #{results[:contaminated]}"
    puts "Errors: #{results[:errors].count}" if results[:errors].any?
    results[:errors].each { |e| puts "  Song ##{e[:song_id]}: #{e[:error]}" }
  end

  desc 'Fix songs with cross-contaminated ISRCs by removing foreign ISRCs. ' \
       'Usage: rake data_repair:fix_contaminated_isrcs[500]'
  task :fix_contaminated_isrcs, [:limit] => :environment do |_t, args|
    limit = (args[:limit] || 500).to_i
    puts "Fixing up to #{limit} songs with ISRC cross-contamination..."
    puts '=' * 80

    repair = IsrcCrossContaminationRepair.new(dry_run: false, limit:)
    results = repair.run

    puts "\n#{'=' * 80}"
    puts "Checked: #{results[:checked]}, Contaminated: #{results[:contaminated]}, Fixed: #{results[:fixed]}"
    puts "Errors: #{results[:errors].count}" if results[:errors].any?
    results[:errors].each { |e| puts "  Song ##{e[:song_id]}: #{e[:error]}" }
  end
end
