# frozen_string_literal: true

class TrackExtractor::SongExtractor < TrackExtractor
  TITLE_SIMILARITY_THRESHOLD = 70

  def extract
    @song = find_or_create_song
    maybe_sanitize_title(@song)
    maybe_update_spotify_data(@song)
    maybe_update_preview_urls(@song)
    maybe_update_release_date(@song)
    @song
  end

  private

  def find_or_create_song
    if @track.present? && @track&.track.present? && find_by_track.present?
      find_by_track
    else
      find_or_create_by_title
    end
  rescue StandardError => e
    ExceptionNotifier.notify(e)
    nil
  end

  def maybe_sanitize_title(song)
    return if song.blank?

    sanitized = TitleSanitizer.sanitize(song.title)
    song.update(title: sanitized) if sanitized != song.title
  end

  def maybe_update_preview_urls(song)
    return if song.blank?

    updates = {}
    updates[:spotify_preview_url] = spotify_preview_url if song.spotify_preview_url.blank? && spotify_preview_url.present?
    updates[:deezer_preview_url] = deezer_preview_url if song.deezer_preview_url.blank? && deezer_preview_url.present?
    updates[:itunes_preview_url] = itunes_preview_url if song.itunes_preview_url.blank? && itunes_preview_url.present?

    song.update(updates) if updates.present?
  end

  def maybe_update_release_date(song)
    return if song.release_date.present? || release_date.blank?

    song.update(release_date:, release_date_precision:)
  end

  def maybe_update_spotify_data(song)
    return if song.blank? || @track.blank?
    return unless @track.respond_to?(:spotify_song_url)

    updates = build_spotify_updates(song)
    song.update(updates) if updates.present?
  end

  def build_spotify_updates(song)
    updates = {
      id_on_spotify: (id_on_spotify if song.id_on_spotify.blank?),
      spotify_song_url: (spotify_song_url if song.spotify_song_url.blank?),
      spotify_artwork_url: (spotify_artwork_url if song.spotify_artwork_url.blank?),
      duration_ms: (duration_ms if song.duration_ms.blank?)
    }.compact
    updates[:isrcs] = song.isrcs | [isrc] if should_add_isrc?(song)
    updates
  end

  def should_add_isrc?(song)
    return false if isrc.blank? || song.isrcs.include?(isrc)

    # Don't add an ISRC from a different Spotify track to an existing song.
    # This prevents cross-contamination when two different songs share an artist
    # (e.g., "Ik Zing" by Zoë Livay feat. Snelle vs "Laat Het Licht Aan" by Snelle).
    return true if song.id_on_spotify.blank? || id_on_spotify.blank?

    song.id_on_spotify == id_on_spotify
  end

  # Methode for checking if there are songs with the same title.
  # if so the artist id must be check
  # if the artist with the some song is not in the database the song with artist Id must be added
  def find_or_create_by_title
    result = if song_by_artists_and_title.present?
               song_by_artists_and_title
             elsif song_by_artists_and_normalized_title.present?
               song_by_artists_and_normalized_title
             elsif find_by_fuzzy_search.present?
               find_by_fuzzy_search
             elsif @artists.blank?
               Song.find_or_create_by(song_attributes)
             else
               song = Song.new(song_attributes)
               Array.wrap(@artists).each { |artist| song.artists << artist }
               song
             end

    result.is_a?(Song) ? result : result.max_by(&:played)
  end

  def song_by_artists_and_title
    @song_by_artists_and_title ||= Song.joins(:artists)
                                     .where(artists: @artists)
                                     .where('lower(title) LIKE ?', title.downcase)
  end

  # Indexed equality lookup against `normalized_title` (whitespace-, case-, and
  # diacritic-insensitive). Catches scrape variants the exact match misses,
  # e.g., "Ik Bel Je Zo Maar Even Op" vs "Ik Bel Je Zomaar Even Op", before
  # falling through to the more expensive trigram fuzzy search.
  def song_by_artists_and_normalized_title
    @song_by_artists_and_normalized_title ||= begin
      key = Song.normalize_title(title)
      key.present? ? Song.joins(:artists).where(artists: @artists).where(normalized_title: key) : Song.none
    end
  end

  def find_by_fuzzy_search
    return @find_by_fuzzy_search if defined?(@find_by_fuzzy_search)

    @find_by_fuzzy_search = begin
      return nil if title.blank? || @artists.blank?

      artist_ids = Array.wrap(@artists).map(&:id)
      search_query = "#{Array.wrap(@artists).map(&:name).join(' ')} #{title}"
      Song.search_by_text(search_query).joins(:artists).where(artists: { id: artist_ids }).limit(5).find do |song|
        (JaroWinkler.similarity(title.downcase, song.title.downcase) * 100).to_i >= TITLE_SIMILARITY_THRESHOLD
      end
    end
  end

  # ISRC is checked first because it uniquely identifies a recording regardless of
  # which platform version is found. This prevents duplicate songs when the scraper
  # and recognizer find different platform versions of the same recording
  # (e.g., "Frank Boeijen" vs "Frank Boeijen Groep" versions with same ISRC).
  # Title similarity is verified on ISRC matches to guard against cross-contaminated
  # ISRCs where a foreign ISRC was incorrectly added to an unrelated song.
  def find_by_track
    @find_by_track ||= find_by_isrc ||
                       (id_on_spotify.present? && Song.find_by(id_on_spotify:)) ||
                       (id_on_deezer.present? && Song.find_by(id_on_deezer:)) ||
                       (id_on_itunes.present? && Song.find_by(id_on_itunes:))
  end

  def find_by_isrc
    return nil if isrc.blank?

    song = Song.where('? = ANY(isrcs)', isrc).first
    return nil if song.blank?
    return song if isrc_title_match?(song)

    nil
  end

  def isrc_title_match?(song)
    return true if title.blank? || song.title.blank?

    normalized_import = normalize_title_for_comparison(title)
    normalized_song = normalize_title_for_comparison(song.title)
    (JaroWinkler.similarity(normalized_import.downcase, normalized_song.downcase) * 100).to_i >= TITLE_SIMILARITY_THRESHOLD
  end

  def normalize_title_for_comparison(raw_title)
    normalized = raw_title.dup
    # Strip featured artist parentheticals: (feat. ...), (ft. ...), (featuring ...)
    normalized.gsub!(/\s*\((?:feat|ft|featuring)\.?\s+[^)]+\)/i, '')
    # Strip subtitle suffixes after " - " (Spotify format for remasters, movie credits, etc.)
    normalized.sub!(/\s+-\s+.+$/, '')
    normalized.strip
  end

  def title
    @track&.title || super
  end

  def id_on_spotify
    return nil unless @track.respond_to?(:spotify_song_url)

    @track&.id
  end

  def id_on_deezer
    return nil unless @track.respond_to?(:deezer_song_url)

    @track&.id
  end

  def id_on_itunes
    return nil unless @track.respond_to?(:itunes_song_url)

    @track&.id
  end

  def isrc
    @track&.isrc
  end

  def duration_ms
    @track&.duration_ms if @track.respond_to?(:duration_ms)
  end

  # Spotify methods
  def spotify_song_url
    @track&.spotify_song_url if @track.respond_to?(:spotify_song_url)
  end

  def spotify_artwork_url
    @track&.spotify_artwork_url if @track.respond_to?(:spotify_artwork_url)
  end

  def spotify_preview_url
    @track&.spotify_preview_url if @track.respond_to?(:spotify_preview_url)
  end

  # Deezer methods
  def deezer_song_url
    @track&.deezer_song_url if @track.respond_to?(:deezer_song_url)
  end

  def deezer_artwork_url
    @track&.deezer_artwork_url if @track.respond_to?(:deezer_artwork_url)
  end

  def deezer_preview_url
    @track&.deezer_preview_url if @track.respond_to?(:deezer_preview_url)
  end

  # iTunes methods
  def itunes_song_url
    @track&.itunes_song_url if @track.respond_to?(:itunes_song_url)
  end

  def itunes_artwork_url
    @track&.itunes_artwork_url if @track.respond_to?(:itunes_artwork_url)
  end

  def itunes_preview_url
    @track&.itunes_preview_url if @track.respond_to?(:itunes_preview_url)
  end

  def release_date
    @track&.release_date
  end

  def release_date_precision
    @track&.release_date_precision if @track.respond_to?(:release_date_precision)
  end

  def song_attributes
    attrs = {
      title:,
      isrcs: [isrc].compact,
      release_date:,
      release_date_precision:
    }

    # Add Spotify attributes if available
    if @track.respond_to?(:spotify_song_url)
      attrs[:spotify_song_url] = spotify_song_url
      attrs[:spotify_artwork_url] = spotify_artwork_url
      attrs[:spotify_preview_url] = spotify_preview_url
      attrs[:id_on_spotify] = id_on_spotify
      attrs[:duration_ms] = duration_ms
    end

    # Add Deezer attributes if available
    if @track.respond_to?(:deezer_song_url)
      attrs[:deezer_song_url] = deezer_song_url
      attrs[:deezer_artwork_url] = deezer_artwork_url
      attrs[:deezer_preview_url] = deezer_preview_url
      attrs[:id_on_deezer] = id_on_deezer
    end

    # Add iTunes attributes if available
    if @track.respond_to?(:itunes_song_url)
      attrs[:itunes_song_url] = itunes_song_url
      attrs[:itunes_artwork_url] = itunes_artwork_url
      attrs[:itunes_preview_url] = itunes_preview_url
      attrs[:id_on_itunes] = id_on_itunes
    end

    attrs.compact
  end
end
