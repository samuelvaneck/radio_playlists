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
    return if artist_name.blank? || title.blank?

    artist_ids = find_artist_ids
    return if artist_ids.blank?

    Song.joins(:artists)
        .where(artists: { id: artist_ids })
        .where('LOWER(songs.title) = ?', title.downcase)
        .first
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
