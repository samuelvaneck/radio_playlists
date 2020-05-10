# frozen_string_literal: true

class Song < ActiveRecord::Base
  has_many :generalplaylists
  has_many :counters
  has_many :radiostations, through: :generalplaylists
  has_many :artists_songs
  has_many :artists, through: :artists_songs

  # validates :artist, presence: true

  def self.search_title(title)
    where('title ILIKE ?', "%#{title}%")
  end

  def self.search(params)
    start_time = params[:start_time].present? ? Time.zone.strptime(params[:start_time], '%Y-%m-%dT%R') : 1.week.ago
    end_time = params[:end_time].present? ? Time.zone.strptime(params[:end_time], '%Y-%m-%dT%R') : Time.zone.now

    songs = Generalplaylist.joins(:song).all
    songs.where!('songs.fullname ILIKE ?', "%#{params[:search_term]}%") if params[:search_term].present?
    songs.where!('radiostation_id = ?', params[:radiostation_id]) if params[:radiostation_id].present?
    songs.where!('generalplaylists.created_at > ?', start_time)
    songs.where!('generalplaylists.created_at < ?', end_time)
    songs
  end

  def self.group_and_count(songs)
    songs.group(:song_id).count.sort_by { |_song_id, counter| counter }.reverse
  end
end
