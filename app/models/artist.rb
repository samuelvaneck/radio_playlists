# frozen_string_literal: true

# == Schema Information
#
# Table name: artists
#
#  id                  :bigint           not null, primary key
#  name                :string
#  image               :string
#  genre               :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  spotify_artist_url  :string
#  spotify_artwork_url :string
#  id_on_spotify       :string
#

class Artist < ActiveRecord::Base
  include GraphConcern

  has_many :artists_songs
  has_many :songs, through: :artists_songs
  has_many :playlists, through: :songs

  validates :name, presence: true

  def self.most_played(params)
    start_time = params[:start_time].present? ? Time.zone.strptime(params[:start_time], '%Y-%m-%dT%R') : 1.week.ago
    end_time = params[:end_time].present? ? Time.zone.strptime(params[:end_time], '%Y-%m-%dT%R') : Time.zone.now
    where_radio_station = params[:radio_station_id].present? ? "AND playlists.radio_station_id = #{params[:radio_station_id]}" : ''
    where_artist = params[:search_term].present? ? "AND artists.name ILIKE '%#{params[:search_term]}%'" : ''

    query = <<~SQL
      SELECT DISTINCT
             artists.id,
             artists.name,
             artists.image,
             artists.id_on_spotify,
             artists.spotify_artist_url,
             artists.spotify_artwork_url,
             COUNT(DISTINCT playlists.id) AS counter
      FROM playlists
        INNER JOIN songs ON playlists.song_id = songs.id
        INNER JOIN artists_songs ON artists_songs.song_id = songs.id
        INNER JOIN artists ON artists.id = artists_songs.artist_id
      WHERE (playlists.created_at > date_trunc('second'::text, '#{start_time}'::timestamp with time zone) 
         AND playlists.created_at < date_trunc('second'::text, '#{end_time}'::timestamp with time zone))
         #{where_radio_station}
         #{where_artist}
      GROUP BY artists.id, artists.name
      ORDER BY counter DESC
    SQL

    find_by_sql(query)
  end

  def self.spotify_track_to_artist(track)
    track.artists.map do |track_artist|
      artist = Artist.find_or_initialize_by(id_on_spotify: track_artist['id']) || Artist.find_or_initialize_by(name: track_artist['name'])
      spotify_artwork_url = track_artist['images'][0]['url'] if track_artist['images'].present?
      artist.assign_attributes(
        name: track_artist['name'],
        spotify_artist_url: track_artist.dig('external_urls', 'spotify'),
        spotify_artwork_url:,
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
