# frozen_string_literal: true

class DuplicateArtistMerger
  FUZZY_NAME_THRESHOLD = 80

  attr_reader :groups

  def initialize
    @groups = []
  end

  def find_duplicates
    @groups = []
    find_spotify_id_duplicates
    find_fuzzy_name_duplicates
    @groups
  end

  def merge_all
    find_duplicates if @groups.empty?
    return { merged: 0, deleted: 0 } if @groups.empty?

    merged_count = 0
    deleted_count = 0

    @groups.each do |group|
      group[:duplicates].each do |duplicate|
        merge_artist(duplicate, group[:keeper])
        deleted_count += 1
      end
      merged_count += 1
    end

    { merged: merged_count, deleted: deleted_count }
  end

  def merge_artist(source, target)
    ActiveRecord::Base.transaction do
      reassign_songs(source, target)
      reassign_chart_positions(source, target)
      enrich_target(target, source)
      source.reload.destroy!
    end
  end

  private

  def find_spotify_id_duplicates
    duplicate_spotify_ids = Artist
                              .where.not(id_on_spotify: [nil, ''])
                              .group(:id_on_spotify)
                              .having('COUNT(*) > 1')
                              .pluck(:id_on_spotify)

    duplicate_spotify_ids.each do |spotify_id|
      artists = Artist.includes(:songs).where(id_on_spotify: spotify_id).to_a
      keeper, duplicates = select_keeper_and_duplicates(artists)
      @groups << { keeper:, duplicates:, reason: "same Spotify ID: #{spotify_id}" }
    end
  end

  def find_fuzzy_name_duplicates
    seen_ids = @groups.flat_map { |g| [g[:keeper].id] + g[:duplicates].map(&:id) }.to_set
    name_groups = build_name_groups(seen_ids)

    name_groups.each_value do |entries|
      next if entries.size < 2

      artists_in_group = entries.map { |e| e[:artist] }
      keeper, duplicates = select_keeper_and_duplicates(artists_in_group)
      @groups << { keeper:, duplicates:, reason: 'fuzzy name match' }
    end
  end

  def build_name_groups(seen_ids)
    name_groups = {}

    Artist.includes(:songs).order(:id).find_each do |artist|
      next if seen_ids.include?(artist.id)

      normalized = normalize_name(artist.name)
      matched_key = find_matching_group(name_groups, normalized)
      entry = { artist:, normalized: }

      if matched_key
        name_groups[matched_key] << entry
      else
        name_groups[normalized] = [entry]
      end
    end

    name_groups
  end

  def find_matching_group(name_groups, normalized)
    name_groups.each do |key, group|
      return key if names_match?(normalized, group.first[:normalized])
    end
    nil
  end

  def select_keeper_and_duplicates(artists)
    sorted = artists.sort_by do |a|
      [a.id_on_spotify.present? ? 0 : 1, -a.songs.size, a.id]
    end
    [sorted.first, sorted[1..]]
  end

  def normalize_name(name)
    normalized = name.to_s.downcase.strip
    normalized = "#{Regexp.last_match(2).strip} #{Regexp.last_match(1).strip}" if normalized =~ /^(.+),\s*(.+)$/
    normalized.gsub(/[^\w\s]/, '').gsub(/\s+/, ' ').strip
  end

  def names_match?(name1, name2)
    return true if name1 == name2

    (JaroWinkler.similarity(name1, name2) * 100).to_i >= FUZZY_NAME_THRESHOLD
  end

  def reassign_songs(source, target)
    source.artists_songs.each do |artists_song|
      existing = ArtistsSong.find_by(artist_id: target.id, song_id: artists_song.song_id)
      if existing
        artists_song.destroy
      else
        artists_song.update!(artist_id: target.id)
      end
    end
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

  def enrich_target(target, source) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    updates = {}
    updates[:id_on_spotify] = source.id_on_spotify if target.id_on_spotify.blank? && source.id_on_spotify.present?
    updates[:image] = source.image if target.image.blank? && source.image.present?
    updates[:spotify_artist_url] = source.spotify_artist_url if target.spotify_artist_url.blank? && source.spotify_artist_url.present?
    updates[:spotify_artwork_url] = source.spotify_artwork_url if target.spotify_artwork_url.blank? && source.spotify_artwork_url.present?
    updates[:instagram_url] = source.instagram_url if target.instagram_url.blank? && source.instagram_url.present?
    updates[:website_url] = source.website_url if target.website_url.blank? && source.website_url.present?
    updates[:genres] = (target.genres + source.genres).uniq if source.genres.present?
    updates[:country_of_origin] = (target.country_of_origin + source.country_of_origin).uniq if source.country_of_origin.present?
    updates[:lastfm_tags] = (target.lastfm_tags + source.lastfm_tags).uniq if source.lastfm_tags.present?
    updates[:spotify_popularity] = source.spotify_popularity if source.spotify_popularity.to_i > target.spotify_popularity.to_i
    updates[:spotify_followers_count] = source.spotify_followers_count if source.spotify_followers_count.to_i > target.spotify_followers_count.to_i
    updates[:lastfm_listeners] = source.lastfm_listeners if source.lastfm_listeners.to_i > target.lastfm_listeners.to_i
    updates[:lastfm_playcount] = source.lastfm_playcount if source.lastfm_playcount.to_i > target.lastfm_playcount.to_i
    target.update!(updates) if updates.present?
  end
end
