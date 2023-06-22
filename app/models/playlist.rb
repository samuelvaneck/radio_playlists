# frozen_string_literal: true

# == Schema Information
#
# Table name: playlists
#
#  id                  :bigint           not null, primary key
#  song_id             :bigint
#  radio_station_id    :bigint
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  broadcast_timestamp :datetime
#  scraper_import      :boolean          default(FALSE)
#

class Playlist < ActiveRecord::Base
  belongs_to :song
  belongs_to :radio_station
  has_many :artists, through: :song

  scope :scraper_imported, -> { where(scraper_import: true) }
  scope :recognizer_imported, -> { where(scraper_import: false) }

  validate :today_unique_playlist_item

  def self.last_played(params)
    start_time = params[:start_time].present? ? Time.zone.strptime(params[:start_time], '%Y-%m-%dT%R') : 1.day.ago
    end_time = params[:end_time].present? ? Time.zone.strptime(params[:end_time], '%Y-%m-%dT%R') : Time.zone.now
    where_radio_station = params[:radio_station_id].present? ? "AND playlists.radio_station_id = #{params[:radio_station_id]}" : ''
    where_song = params[:search_term].present? ? "AND songs.title ILIKE '%#{params[:search_term]}%' OR artists.name ILIKE '%#{params[:search_term]}%'" : ''

    query = <<~SQL
      SELECT 
        playlists.id,
        playlists.song_id,
        playlists.radio_station_id,
        playlists.created_at,
        playlists.broadcast_timestamp,
        playlists.scraper_import
      FROM playlists
        INNER JOIN songs ON playlists.song_id = songs.id
        INNER JOIN radio_stations ON playlists.radio_station_id = radio_stations.id
        INNER JOIN artists_songs ON songs.id = artists_songs.song_id 
        INNER JOIN artists ON artists.id = artists_songs.artist_id
      WHERE (playlists.created_at > date_trunc('second'::text, '#{start_time}'::timestamp with time zone) 
         AND playlists.created_at < date_trunc('second'::text, '#{end_time}'::timestamp with time zone))
         #{where_radio_station}
         #{where_song}
      GROUP BY playlists.id
      ORDER BY playlists.broadcast_timestamp DESC
    SQL

    find_by_sql(query)
  end

  # def self.search(params)
  #   start_time = params[:start_time].present? ? Time.zone.strptime(params[:start_time], '%Y-%m-%dT%R') : 1.day.ago
  #   end_time =  params[:end_time].present? ? Time.zone.strptime(params[:end_time], '%Y-%m-%dT%R') : Time.zone.now
  #
  #   playlists = Playlist.where('playlists.created_at > ? AND playlists.created_at < ?', start_time, end_time)
  #                       .includes(:radio_station, :artists, song: [:artists])
  #                       .references(:artists, :song)
  #                       .order(created_at: :DESC)
  #   playlists.where!(search_query, search_value(params), search_value(params)) if params[:search_term].present?
  #   playlists.where!('radio_station_id = ?', params[:radio_station_id]) if params[:radio_station_id].present?
  #   playlists.uniq
  # end

  def deduplicate
    return unless duplicate?

    song = Song.find(song_id)
    destroy
    song.cleanup
  end

  def duplicate?
    Playlist.where(radio_station:, broadcast_timestamp:).count > 1
  end

  # def self.search_query
  #   'songs.title ILIKE ? OR artists.name ILIKE ?'
  # end

  # def self.search_value(params)
  #   "%#{params[:search_term]}%"
  # end

  def self.add_playlist(radio_station, song, broadcast_timestamp, scraper_import)
    create(radio_station:, song:, broadcast_timestamp:, scraper_import:)
  end

  private

  def today_unique_playlist_item
    exisiting_record = Playlist.joins(:song, :radio_station)
                               .where('broadcast_timestamp = ? AND radio_stations.id = ?', broadcast_timestamp, radio_station_id)
                               .present?
    errors.add(:base, 'none unique playlist') if exisiting_record
  end
end
