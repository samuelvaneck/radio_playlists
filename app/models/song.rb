# frozen_string_literal: true

class Song < ActiveRecord::Base
  include GraphConcern

  has_many :artists_songs
  has_many :artists, through: :artists_songs
  has_many :playlists
  has_many :radio_stations, through: :playlists
  after_commit :update_fullname, on: %i[create update]

  MULTIPLE_ARTIST_REGEX = ';|\bfeat\.|\bvs\.|\bft\.|\bft\b|\bfeat\b|\bft\b|&|\bvs\b|\bversus|\band\b|\bmet\b|\b,|\ben\b|\/'
  TRACK_FILTERS = ['karoke', 'cover', 'made famous', 'tribute', 'backing business', 'arcade', 'instrumental', '8-bit', '16-bit'].freeze
  public_constant :MULTIPLE_ARTIST_REGEX
  public_constant :TRACK_FILTERS

  def self.search_title(title)
    where('title ILIKE ?', "%#{title}%")
  end

  def self.search(params)
    start_time = params[:start_time].present? ? Time.zone.strptime(params[:start_time], '%Y-%m-%dT%R') : 1.week.ago
    end_time = params[:end_time].present? ? Time.zone.strptime(params[:end_time], '%Y-%m-%dT%R') : Time.zone.now

    songs = Playlist.joins(:song, :artists).all
    songs.where!(search_query, search_value(params), search_value(params)) if params[:search_term].present?
    songs.where!('radio_station_id = ?', params[:radio_station_id]) if params[:radio_station_id].present?
    songs.where!('playlists.created_at > ?', start_time)
    songs.where!('playlists.created_at < ?', end_time)
    songs.distinct
  end

  def self.group_and_count(songs)
    songs.group(:song_id)
         .count.sort_by { |_song_id, counter| counter }
         .reverse
  end

  def self.spotify_track_to_song(track)
    song = Song.find_or_initialize_by(id_on_spotify: track.track['id'])
    song.assign_attributes(
      title: track.title,
      spotify_song_url: track.spotify_song_url,
      spotify_artwork_url: track.spotify_artwork_url,
      isrc: track.isrc
    )
    song.save
    song
  end

  def cleanup
    destroy if playlists.blank?
    artists.each(&:cleanup)
  end

  def self.find_and_remove_absolute_songs
    Song.all.each do |song|
      songs = find_same_songs(song)
      correct_song = songs.last
      next if songs.count <= 1 || correct_song.blank?

      remove_absolute_songs(songs, correct_song)
    end
  end

  def self.search_query
    'songs.title ILIKE ? OR artists.name ILIKE ?'
  end

  def self.search_value(params)
    "%#{params[:search_term]}%"
  end

  def update_artists(song_artists)
    self.artists = Array.wrap(song_artists) if song_artists.present?
  end

  private

  def find_same_songs(song)
    artist_ids = song.artists.map(&:id)
    Song.joins(:artists).where(artists: { id: artist_ids }).where('lower(title) = ?', song.title.downcase)
  end

  def remove_absolute_songs(songs, correct_song)
    songs.map(&:id).each do |id|
      next if id == correct_song.id

      absolute_song = Song.find(id) rescue next
      gps = Playlist.where(song: absolute_song)
      gps.each { |gp| gp.update_attribute('song_id', correct_song.id) }
      absolute_song.cleanup
    end
  end

  def update_fullname
    update_column(:fullname, "#{Array.wrap(artists).map(&:name).join(' ')} #{title}")
  end
end
