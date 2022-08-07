# frozen_string_literal: true

class Song < ActiveRecord::Base
  has_many :artists_songs
  has_many :artists, through: :artists_songs
  has_many :generalplaylists
  has_many :radiostations, through: :generalplaylists

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

    songs = Generalplaylist.joins(:song, :artists).all
    songs.where!(search_query, search_value(params), search_value(params)) if params[:search_term].present?
    songs.where!('radiostation_id = ?', params[:radiostation_id]) if params[:radiostation_id].present?
    songs.where!('generalplaylists.created_at > ?', start_time)
    songs.where!('generalplaylists.created_at < ?', end_time)
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
      spotify_song_url: track.track['external_urls']['spotify'],
      spotify_artwork_url:  track.track['album']['images'][0]['url']
    )
    song.save
    song
  end

  def cleanup
    destroy if generalplaylists.blank?
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

  def graph_data
    playlists = Generalplaylist.joins(:song)
                               .where(song: self)
                               .where('generalplaylists.created_at > ?', 1.month.ago)
                               .sort_by(&:broadcast_timestamp)

    min_date, max_date = playlists.map { |playlist| playlist.broadcast_timestamp.strftime('%Y-%m-%d') }.minmax

    playlists = playlists.each_with_object({}) do |playlist, result|
      broadcast_timestamp, radiostation_id = playlist.values_at(:broadcast_timestamp, :radiostation_id)
      result[broadcast_timestamp.strftime('%Y-%m-%d')] ||= {}
      result[broadcast_timestamp.strftime('%Y-%m-%d')][radiostation_id] ||= []
      result[broadcast_timestamp.strftime('%Y-%m-%d')][radiostation_id] << playlist
    end

    playlists = graph_data_series(playlists, min_date, max_date).compact
    playlists << { columns: Radiostation.all.map(&:name) }
    playlists
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
      gps = Generalplaylist.where(song: absolute_song)
      gps.each { |gp| gp.update_attribute('song_id', correct_song.id) }
      absolute_song.cleanup
    end
  end

  def graph_data_series(playlists, min_date, max_date)
    min_date.upto(max_date).map do |date|
      date.try(:to_date)
      result = { date: }
      grouped_playlists = playlists[date]

      Radiostation.all.each do |radio_station|
        result[radio_station.name] = if grouped_playlists && grouped_playlists[radio_station.id]
                                       grouped_playlists[radio_station.id].count
                                     else
                                       0
                                     end
      end
      result
    rescue Date::Error => _e
      next
    end
  end
end
