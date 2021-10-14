# frozen_string_literal: true

module TrackDataProcessor
  extend ActiveSupport::Concern

  def process_track_data(artist_name, title)
    spotify = Spotify.new(artists: artist_name, title: title)
    spotify.find_spotify_track
    artists = find_or_create_artist(artist_name, spotify)
    song = find_or_create_song(title, spotify, artists)
    [artists, song]
  end

  def find_or_create_artist(name, spotify)
    if spotify.track.present? && spotify.track_artists.present?
      Artist.spotify_track_to_artist(spotify)
    else
      Artist.find_or_initialize_by(name: name)
    end
  end

  def find_or_create_song(title, spotify, artists)
    if spotify.track.present?
      Song.spotify_track_to_song(spotify)
    else
      songs = Song.where('lower(title) = ?', title.downcase)
      song_check(songs, artists, title)
    end
  end

  # Methode for checking if there are songs with the same title.
  # if so the artist id must be check
  # if the artist with the some song is not in the database the song with artist Id must be added
  def song_check(songs, artists, title)
    # If there is no song with the same title create a new one
    result = if songs.blank? || artists.blank?
               Song.find_or_create_by(title: title)
             elsif query_songs(artists, title)
               query_songs(artists, title)
             else
               song = Song.new(title: title, artists: artists)
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
end
