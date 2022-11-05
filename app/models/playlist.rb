# frozen_string_literal: true

class Playlist < ActiveRecord::Base
  belongs_to :song
  belongs_to :radio_station
  has_many :artists, through: :song

  validate :today_unique_playlist_item

  def self.search(params)
    start_time = params[:start_time].present? ? Time.zone.strptime(params[:start_time], '%Y-%m-%dT%R') : 1.week.ago
    end_time =  params[:end_time].present? ? Time.zone.strptime(params[:end_time], '%Y-%m-%dT%R') : Time.zone.now

    playlists = Playlist.joins(:song, :artists).order(created_at: :DESC)
    playlists.where!(search_query, search_value(params), search_value(params)) if params[:search_term].present?
    playlists.where!('radio_station_id = ?', params[:radio_station_id]) if params[:radio_station_id].present?
    playlists.where!('playlists.created_at > ?', start_time)
    playlists.where!('playlists.created_at < ?', end_time)
    playlists.uniq
  end

  def deduplicate
    return unless duplicate?

    song = Song.find(song_id)
    destroy
    song.cleanup
  end

  def duplicate?
    Playlist.where(radio_station:, broadcast_timestamp:).count > 1
  end

  def self.search_query
    'songs.title ILIKE ? OR artists.name ILIKE ?'
  end

  def self.search_value(params)
    "%#{params[:search_term]}%"
  end

  private

  def today_unique_playlist_item
    exisiting_record = Playlist.joins(:song, :radio_station)
                               .where('broadcast_timestamp = ? AND radio_stations.id = ?', broadcast_timestamp, radio_station_id)
                               .present?
    errors.add(:base, 'none unique playlist') if exisiting_record
  end
end
