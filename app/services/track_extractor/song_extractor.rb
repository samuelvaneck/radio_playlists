# frozen_string_literal: true

class TrackExtractor::SongExtractor < TrackExtractor
  def extract
    find_or_create_song
  end

  private

  def find_or_create_song
    if @track.present? && @track&.track.present? && find_by_track.present?
      find_by_track
    else
      find_or_create_by_title
    end
  rescue StandardError => e
    Sentry.capture_exception(e)
    nil
  end

  # Methode for checking if there are songs with the same title.
  # if so the artist id must be check
  # if the artist with the some song is not in the database the song with artist Id must be added
  def find_or_create_by_title
    result = if song_by_artists_and_title.present?
               song_by_artists_and_title
             elsif song_by_artists_and_title.blank? && @artists.blank?
               Song.find_or_create_by(title:)
             else
               song = Song.new(title:)
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

  def find_by_track
    @find_by_track ||= Song.find_by(id_on_spotify:).presence || Song.find_by(isrc:).presence
  end

  def id_on_spotify
    @track&.track['id']
  end

  def isrc
    @track.isrc
  end

  def song_attributes
    {
      title: @track.title,
      spotify_song_url: @track.spotify_song_url,
      spotify_artwork_url: @track.spotify_artwork_url,
      id_on_spotify:,
      isrc:
    }
  end
end
