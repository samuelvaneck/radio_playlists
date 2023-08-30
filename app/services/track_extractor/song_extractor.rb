# frozen_string_literal: true

class TrackExtractor::SongExtractor < TrackExtractor
  def extract
    find_or_create_song
  end

  private

  def find_or_create_song
    if @track.present? && @track&.track.present?
      Song.spotify_track_to_song(@track)
    else
      songs = Song.where('lower(title) = ?', title.downcase)
      song_check(songs)
    end
  rescue StandardError => e
    Sentry.capture_exception(e)
    nil
  end

  # Methode for checking if there are songs with the same title.
  # if so the artist id must be check
  # if the artist with the some song is not in the database the song with artist Id must be added
  def song_check(songs)
    # If there is no song with the same title create a new one
    result = if songs.blank? || @artists.blank?
               Song.find_or_create_by(title:)
             elsif query_songs
               query_songs
             else
               song = Song.new(title:, artists: @artists)
               song.artists << @artists
               song
             end

    result.is_a?(Song) ? result : result.max_by(&:played)
  end

  def query_songs
    artist_ids = Array.wrap(@artists.instance_of?(Array) ? @artists.map(&:id) : @artists.id)
    Song.joins(:artists).where(artists: { id: artist_ids }).where('lower(title) = ?', title.downcase)
  end
end
