# frozen_string_literal: true
module TrackDataProcessor
  extend ActiveSupport::Concern

  def process_track_data(artist_name, title, spotify_url = nil)
    generate_sentry_breadcrumb(artist_name, title)
    args = spotify_service_args(artist_name, title, spotify_url)
    track = Spotify.new(args).track
    artists = find_or_create_artist(artist_name, track)
    song = find_or_create_song(title, track, artists)
    [artists, song]
  rescue StandardError => e
    Sentry.capture_exception(e)
    nil
  end

  def find_or_create_artist(name, track)
    if track.present? && track.artists.present?
      Artist.spotify_track_to_artist(track)
    else
      Artist.find_or_initialize_by(name:)
    end
  rescue StandardError => e
    Sentry.capture_exception(e)
    nil
  end

  def find_or_create_song(title, track, artists)
    if track.present? && track&.track&.present?
      Song.spotify_track_to_song(track)
    else
      songs = Song.where('lower(title) = ?', title.downcase)
      song_check(songs, artists, title)
    end
  rescue StandardError => e
    Sentry.capture_exception(e)
    nil
  end

  # Methode for checking if there are songs with the same title.
  # if so the artist id must be check
  # if the artist with the some song is not in the database the song with artist Id must be added
  def song_check(songs, artists, title)
    # If there is no song with the same title create a new one
    result = if songs.blank? || artists.blank?
               Song.find_or_create_by(title:)
             elsif query_songs(artists, title)
               query_songs(artists, title)
             else
               song = Song.new(title:, artists:)
               song.artists << artists
               song
             end

    result.is_a?(Song) ? result : result.first
  end

  def query_songs(artists, title)
    artist_ids = Array.wrap(artists.instance_of?(Array) ? artists.map(&:id) : artists.id)
    Song.joins(:artists).where(artists: { id: artist_ids }).where('lower(title) = ?', title.downcase)
  end

  def illegal_word_in_title(title)
    # catch more then 4 digits, forward slashes, 2 single qoutes,
    # reklame/reclame/nieuws/pingel and 2 dots
    if title.match(/\d{4,}|\/|'{2,}|(reklame|reclame|nieuws|pingel)|\.{2,}/i)
      Rails.logger.info "Found illegal word in #{title}"
      true
    else
      false
    end
  end

  def generate_sentry_breadcrumb(artist_name, title)
    crumb = Sentry::Breadcrumb.new(
      category: 'import_song',
      data: { artist_naem: artist_name, title:, radio_station: name },
      level: 'info'
    )
    Sentry.add_breadcrumb(crumb)
  end

  def spotify_service_args(artist_name, title, spotify_url = nil)
    args = { artists: artist_name, title: }
    args.merge!({ spotify_track_id: spotify_url.split('/').last }) if spotify_url
    args
  end
end
