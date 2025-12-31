# frozen_string_literal: true
class TrackExtractor::SpotifyTrackFinder < TrackExtractor
  def find
    return if played_song.blank?

    track = Spotify::TrackFinder::Result.new(spotify_service_args)
    track.execute
    track
  end

  private

  def spotify_service_args
    args = { artists: artist_name, title: }
    if spotify_url&.start_with?('spotify:search')
      args[:spotify_search_url] = spotify_url
    elsif spotify_url
      args[:spotify_track_id] = spotify_url.split('/').last
    elsif existing_song_spotify_id.present?
      # Use existing song's Spotify ID to ensure consistent results
      args[:spotify_track_id] = existing_song_spotify_id
    end
    args
  end

  def existing_song_spotify_id
    @existing_song_spotify_id ||= find_existing_song&.id_on_spotify
  end

  def find_existing_song
    # First, try to find by ISRC (most reliable identifier from audio recognition)
    if isrc_code.present?
      song_by_isrc = Song.find_by(isrc: isrc_code)
      return song_by_isrc if song_by_isrc&.id_on_spotify.present?
    end

    # Then try artist + title matching
    return if artist_name.blank? || title.blank?

    artist_ids = find_artist_ids
    return find_by_title_with_fuzzy_artist if artist_ids.blank?

    Song.joins(:artists)
        .where(artists: { id: artist_ids })
        .where('LOWER(songs.title) = ?', title.downcase)
        .first
  end

  # When exact artist match fails, try to find song by title and verify
  # that at least one of the recognized artist names partially matches
  def find_by_title_with_fuzzy_artist
    return if title.blank? || artist_name.blank?

    songs_by_title = Song.where('LOWER(title) = ?', title.downcase)
                         .where.not(id_on_spotify: nil)
                         .includes(:artists)

    recognized_artist_names = split_artist_names.map(&:downcase)

    songs_by_title.find do |song|
      song.artists.any? do |artist|
        artist_name_downcase = artist.name.downcase
        recognized_artist_names.any? do |recognized_name|
          # Check if either name contains the other (handles "Ed Sheeran" vs "Ed Sheeran feat. X")
          artist_name_downcase.include?(recognized_name) || recognized_name.include?(artist_name_downcase)
        end
      end
    end
  end

  def find_artist_ids
    artist_names = split_artist_names
    return [] if artist_names.blank?

    Artist.where('LOWER(name) IN (?)', artist_names.map(&:downcase)).pluck(:id)
  end

  def split_artist_names
    regex = Regexp.new(Song::MULTIPLE_ARTIST_REGEX, Regexp::IGNORECASE)
    if artist_name.match?(regex)
      artist_name.split(regex).map(&:strip).reject(&:blank?)
    else
      [artist_name]
    end
  end
end
