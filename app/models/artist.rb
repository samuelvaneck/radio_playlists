# frozen_string_literal: true

class Artist < ActiveRecord::Base
  has_many :generalplaylists
  has_many :songs
  has_many :radiostations, through: :generalplaylists

  def self.search(params)
    artists = Generalplaylist.joins(:artist).all
    artists.where!('artists.name ILIKE ?', "%#{params[:search_term]}%") if params[:search_term].present?
    artists.where!('radiostation_id = ?', params[:radiostation_id]) if params[:radiostation_id].present?
    artists
  end

  def self.group_and_count(artists)
    artists.group(:artist_id)
           .count.sort_by { |_artist_id, counter| counter }
           .reverse
  end
end
