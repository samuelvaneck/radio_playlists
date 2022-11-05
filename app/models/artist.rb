# frozen_string_literal: true

class Artist < ActiveRecord::Base
  include GraphConcern

  has_many :artists_songs
  has_many :songs, through: :artists_songs
  has_many :playlists, through: :songs

  validates :name, presence: true

  def self.search(params)
    start_time = params[:start_time].present? ? Time.zone.strptime(params[:start_time], '%Y-%m-%dT%R') : 1.week.ago
    end_time = params[:end_time].present? ? Time.zone.strptime(params[:end_time], '%Y-%m-%dT%R') : Time.zone.now

    # artists = Playlist.joins(:artists).all
    artists = Artist.joins(:playlists).all
    artists.where!('artists.name ILIKE ?', "%#{params[:search_term]}%") if params[:search_term].present?
    artists.where!('playlists.radio_station_id = ?', params[:radio_station_id]) if params[:radio_station_id].present?
    artists.where!('playlists.created_at > ?', start_time)
    artists.where!('playlists.created_at < ?', end_time)
    artists
  end

  def self.group_and_count(artists)
    artists.group(:artist_id)
           .count.sort_by { |_artist_id, counter| counter }
           .reverse
  end

  def self.spotify_track_to_artist(track)
    track.artists.map do |track_artist|
      artist = Artist.find_or_initialize_by(id_on_spotify: track_artist['id']) || Artist.find_or_initialize_by(name: track_artist['name'])
      artist.assign_attributes(
        name: track_artist['name'],
        spotify_artist_url: track_artist['external_urls']['spotify'],
        spotify_artwork_url: track_artist['images'][0]['url'],
        id_on_spotify: track_artist['id']
      )
      artist.save
      artist
    end
  end

  def cleanup
    destroy if songs.blank?
  end
end
