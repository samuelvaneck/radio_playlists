# frozen_string_literal: true

class Song < ActiveRecord::Base
  has_many :generalplaylists
  has_many :counters
  has_many :radiostations, through: :generalplaylists
  belongs_to :artist

  validates :artist, presence: true

  def self.search(params)
    query = Song.build_sql_query(params[:search_term], params[:radiostation_id])
    Song.execute_sql(query, params[:search_term], params[:radiostation_id]).to_a
  end

  def self.build_sql_query(search_term = nil, radiostation_id = nil, time = nil)
    sql = "
      SELECT COUNT(songs.id), songs.id, songs.title, songs.spotify_song_url, 
        songs.spotify_artwork_url, artists.name AS artist_name
      FROM songs
      INNER JOIN generalplaylists
        ON generalplaylists.song_id = songs.id
      INNER JOIN artists
        ON artists.id = songs.artist_id 
    "

    if search_term.present? && radiostation_id.present?
      sql += "WHERE songs.fullname ILIKE :song_title
              AND generalplaylists.radiostation_id = :radiostation_id "
    elsif search_term.present?
      sql += "WHERE songs.fullname ILIKE :song_title "
    elsif radiostation_id.present?
      sql += "WHERE generalplaylists.radiostation_id = :radiostation_id "
    end

    sql += "GROUP BY generalplaylists.song_id, songs.id, artists.name
            ORDER BY COUNT(songs.id) DESC"

    sql
  end

  def self.execute_sql(sql_command, search_term = nil, radiostation_id = nil, time = nil)
    connection.execute(sanitize_sql_for_assignment([sql_command, song_title: "%#{search_term}%", radiostation_id: radiostation_id, time: time]))
  end
end
