# frozen_string_literal: true

module TrackDataProcessor
  extend ActiveSupport::Concern

  def process_track_data(artist_name, title)
    spotify_track = Spotify.new(artists: artist_name, title: title).find_spotify_track
    artists = find_or_create_artist(artist_name, spotify_track)
    song = find_or_create_song(title, spotify_track, artists)
    [artists, song]
  end

  def find_or_create_artist(name, spotify_track)
    if spotify_track.present? && spotify_track.artists.present?
      Artist.spotify_track_to_artist(spotify_track)
    else
      Artist.find_or_initialize_by(name: name)
    end
  end

  def find_or_create_song(title, spotify_track, artists)
    if spotify_track.present?
      Song.spotify_track_to_song(spotify_track)
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

    song = result.is_a?(Song) ? result : result.first
    # set spotify song links
    find_spotify_links(song, artists)
    song
  end

  def query_songs(artists, title)
    artist_ids = Array.wrap(artists.instance_of?(Array) ? artists.map(&:id) : artists.id)
    Song.joins(:artists).where(artists: { id: artist_ids }).where('lower(title) = ?', title.downcase)
  end

  def find_spotify_links(song, artists)
    spotify_song = song.spotify_search(artists)
    if spotify_song.present?
      song.assign_attributes(
        title: spotify_song.name,
        spotify_song_url: spotify_song.external_urls['spotify'],
        spotify_artwork_url: spotify_song.album.images[0]['url'],
        id_on_spotify: spotify_song.id
      )
      song.save
    end
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
