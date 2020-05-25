# frozen_string_literal: true

class Song < ActiveRecord::Base
  has_many :generalplaylists
  has_many :counters
  has_many :radiostations, through: :generalplaylists
  belongs_to :artist

  validates :artist, presence: true

  def self.search_title(title)
    where('title ILIKE ?', "%#{title}%")
  end

  def self.search(params)
    songs = Generalplaylist.joins(:song).all
    if params[:search_term].present? || params[:radiostation_id].present?
      songs.where!('songs.fullname ILIKE ?', "%#{params[:search_term]}%") if params[:search_term].present?
      songs.where!('radiostation_id = ?', params[:radiostation_id]) if params[:radiostation_id].present?
    end
    songs
  end

  def self.group_and_count(songs)
    songs.group(:song_id).count.sort_by { |_song_id, counter| counter }.reverse
  end
end
