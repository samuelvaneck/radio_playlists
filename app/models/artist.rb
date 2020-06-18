# frozen_string_literal: true

class Artist < ActiveRecord::Base
  has_many :artists_songs
  has_many :songs, through: :artists_songs
  has_many :generalplaylists, through: :songs
  has_many :radiostations, through: :generalplaylists

  def self.search(params)
    start_time = params[:start_time].present? ? Time.zone.strptime(params[:start_time], '%Y-%m-%dT%R') : 1.week.ago
    end_time = params[:end_time].present? ? Time.zone.strptime(params[:end_time], '%Y-%m-%dT%R') : Time.zone.now

    # artists = Generalplaylist.joins(:artists).all
    artists = Artist.joins(:generalplaylists).all
    artists.where!('artists.name ILIKE ?', "%#{params[:search_term]}%") if params[:search_term].present?
    artists.where!('generalplaylists.radiostation_id', params[:radiostation_id]) if params[:radiostation_id].present?
    artists.where!('generalplaylists.created_at > ?', start_time)
    artists.where!('generalplaylists.created_at < ?', end_time)
    artists
  end

  def self.group_and_count(artists)
    artists.uniq.map { |artist| [artist.id, artist.generalplaylists.count] }
           .sort_by { |_artist_id, counter| counter }.reverse
  end
end
