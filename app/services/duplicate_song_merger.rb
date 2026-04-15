# frozen_string_literal: true

class DuplicateSongMerger
  FUZZY_TITLE_THRESHOLD = 92

  attr_reader :groups

  def initialize
    @groups = []
  end

  def find_duplicates
    @groups = []
    find_spotify_id_duplicates
    find_fuzzy_title_duplicates
    @groups
  end

  def merge_all
    find_duplicates if @groups.empty?
    return { merged: 0, deleted: 0 } if @groups.empty?

    merged_count = 0
    deleted_count = 0

    @groups.each do |group|
      group[:duplicates].each do |duplicate|
        merge_song(duplicate, group[:keeper])
        deleted_count += 1
      end
      merged_count += 1
    end

    { merged: merged_count, deleted: deleted_count }
  end

  def merge_song(source, target)
    ActiveRecord::Base.transaction do
      merge_air_plays(source, target)
      merge_radio_station_songs(source, target)
      reassign_chart_positions(source, target)
      source.song_import_logs.update_all(song_id: target.id) # rubocop:disable Rails/SkipsModelValidations
      transfer_music_profile(source, target)
      enrich_target(target, source)
      source.reload.destroy!
    end
  end

  private

  def find_spotify_id_duplicates
    duplicate_spotify_ids = Song
                              .where.not(id_on_spotify: [nil, ''])
                              .group(:id_on_spotify)
                              .having('COUNT(*) > 1')
                              .pluck(:id_on_spotify)

    duplicate_spotify_ids.each do |spotify_id|
      songs = Song.includes(:artists).where(id_on_spotify: spotify_id).to_a
      next unless same_artists?(songs)

      keeper, duplicates = select_keeper_and_duplicates(songs)
      @groups << { keeper:, duplicates:, reason: "same Spotify ID: #{spotify_id}" }
    end
  end

  def find_fuzzy_title_duplicates
    seen_ids = @groups.flat_map { |g| [g[:keeper].id] + g[:duplicates].map(&:id) }.to_set

    # Group songs by their sorted artist IDs to only compare songs with the same artists
    artist_groups = build_artist_groups(seen_ids)

    artist_groups.each_value do |songs|
      title_groups = build_title_groups(songs)

      title_groups.each_value do |entries|
        next if entries.size < 2

        songs_in_group = entries.map { |e| e[:song] }
        filtered = filter_conflicting_spotify_ids(songs_in_group)
        next if filtered.size < 2

        keeper, duplicates = select_keeper_and_duplicates(filtered)
        @groups << { keeper:, duplicates:, reason: 'fuzzy title match' }
      end
    end
  end

  def build_artist_groups(seen_ids)
    # Phase 1: Build artist_key => [song_id] mapping using lightweight SQL (no AR objects loaded)
    rows = ActiveRecord::Base.connection.select_all(<<~SQL.squish)
      SELECT song_id, string_agg(artist_id::text, ',' ORDER BY artist_id) AS artist_key
      FROM artists_songs
      GROUP BY song_id
    SQL

    id_groups = Hash.new { |h, k| h[k] = [] }
    rows.each do |row|
      song_id = row['song_id'].to_i
      next if seen_ids.include?(song_id)

      id_groups[row['artist_key']] << song_id
    end
    rows = nil # rubocop:disable Lint/UselessAssignment

    # Phase 2: Only load Song objects for groups with potential duplicates
    id_groups.each_with_object({}) do |(artist_key, song_ids), groups|
      next if song_ids.size < 2

      groups[artist_key] = Song.includes(:artists).where(id: song_ids).to_a
    end
  end

  def build_title_groups(songs)
    title_groups = {}
    bucket_index = Hash.new { |h, k| h[k] = [] }

    songs.each do |song|
      normalized = normalize_title(song.title)
      matched_key = find_matching_title(bucket_index, normalized)
      entry = { song:, normalized: }

      if matched_key
        title_groups[matched_key] << entry
      else
        title_groups[normalized] = [entry]
        title_bucket_keys(normalized).each { |bucket| bucket_index[bucket] << normalized }
      end
    end

    title_groups
  end

  def find_matching_title(bucket_index, normalized)
    candidates = title_bucket_keys(normalized).flat_map { |bucket| bucket_index[bucket] }.uniq

    candidates.each do |candidate_key|
      return candidate_key if titles_match?(normalized, candidate_key)
    end
    nil
  end

  def title_bucket_keys(normalized)
    tokens = normalized.split
    keys = tokens.map { |t| t[0, 3] }
    keys << tokens.map { |t| t[0] }.sort.join
    keys.compact.uniq
  end

  def same_artists?(songs)
    artist_id_sets = songs.map { |s| s.artists.map(&:id).sort }
    artist_id_sets.uniq.size == 1
  end

  def filter_conflicting_spotify_ids(songs)
    primary_spotify_id = songs.filter_map(&:id_on_spotify).tally.max_by(&:last)&.first
    return songs if primary_spotify_id.blank?

    songs.select { |s| s.id_on_spotify.blank? || s.id_on_spotify == primary_spotify_id }
  end

  def select_keeper_and_duplicates(songs)
    sorted = songs.sort_by do |s|
      [s.id_on_spotify.present? ? 0 : 1, -s.air_plays.count, s.id]
    end
    [sorted.first, sorted[1..]]
  end

  def normalize_title(title)
    title.to_s.downcase.strip.gsub(/[^\w\s]/, '').gsub(/\s+/, ' ').strip
  end

  def titles_match?(title1, title2) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    return true if title1 == title2
    return false if (title1.length - title2.length).abs > 2

    tokens1 = title1.split
    tokens2 = title2.split
    return false if tokens1.size != tokens2.size
    return false if tokens1.size == 1 && (title1.length < 6 || title2.length < 6)

    full_similarity = (JaroWinkler.similarity(title1, title2) * 100).to_i
    threshold = tokens1.size == 1 ? 95 : FUZZY_TITLE_THRESHOLD
    return false if full_similarity < threshold

    return true if tokens1.size <= 1

    tokens1.zip(tokens2).all? do |t1, t2|
      length_diff = (t1.length - t2.length).abs
      length_diff <= 1 && (JaroWinkler.similarity(t1, t2) * 100).to_i >= FUZZY_TITLE_THRESHOLD
    end
  end

  def merge_air_plays(source, target)
    source.air_plays.find_each do |air_play|
      existing = AirPlay.find_by(song_id: target.id, radio_station_id: air_play.radio_station_id, broadcasted_at: air_play.broadcasted_at)
      if existing
        air_play.destroy
      else
        air_play.update_columns(song_id: target.id)
      end
    end
  end

  def merge_radio_station_songs(source, target)
    source.radio_station_songs.find_each do |rss|
      existing = RadioStationSong.find_by(song_id: target.id, radio_station_id: rss.radio_station_id)
      if existing
        existing.update!(first_broadcasted_at: rss.first_broadcasted_at) if should_update_broadcasted_at?(existing, rss)
        rss.destroy
      else
        rss.update!(song_id: target.id)
      end
    end
  end

  def should_update_broadcasted_at?(existing, source_rss)
    source_rss.first_broadcasted_at.present? &&
      (existing.first_broadcasted_at.blank? || source_rss.first_broadcasted_at < existing.first_broadcasted_at)
  end

  def reassign_chart_positions(source, target)
    source.chart_positions.each do |cp|
      existing = ChartPosition.find_by(positianable: target, chart_id: cp.chart_id)
      if existing
        existing.update!(position: [existing.position, cp.position].min, counts: [existing.counts, cp.counts].max)
        cp.destroy
      else
        cp.update!(positianable: target)
      end
    end
  end

  def transfer_music_profile(source, target)
    source.music_profile.update!(song_id: target.id) if source.music_profile.present? && target.music_profile.blank?
  end

  def enrich_target(target, source) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    updates = {}
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
    updates[:isrcs] = (target.isrcs + source.isrcs).uniq if source.isrcs.present?
    updates[:lastfm_tags] = (target.lastfm_tags + source.lastfm_tags).uniq if source.lastfm_tags.present?
    updates[:popularity] = source.popularity if source.popularity.to_i > target.popularity.to_i
    updates[:lastfm_listeners] = source.lastfm_listeners if source.lastfm_listeners.to_i > target.lastfm_listeners.to_i
    updates[:lastfm_playcount] = source.lastfm_playcount if source.lastfm_playcount.to_i > target.lastfm_playcount.to_i
    updates[:duration_ms] = source.duration_ms if target.duration_ms.blank? && source.duration_ms.present?
    target.update!(updates) if updates.present?
  end
end
