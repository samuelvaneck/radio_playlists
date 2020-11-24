# frozen_string_literal: true

class Generalplaylist < ActiveRecord::Base
  belongs_to :song
  belongs_to :radiostation
  has_many :artists, through: :song

  validate :today_unique_playlist_item

  def self.search(params)
    start_time = params[:start_time].present? ? Time.zone.strptime(params[:start_time], '%Y-%m-%dT%R') : 1.week.ago
    end_time =  params[:end_time].present? ? Time.zone.strptime(params[:end_time], '%Y-%m-%dT%R') : Time.zone.now

    playlists = Generalplaylist.joins(:song, :artists).order(created_at: :DESC)
    playlists.where!('songs.title ILIKE ? OR artists.name ILIKE ?', "%#{params[:search_term]}%", "%#{params[:search_term]}%") if params[:search_term].present?
    playlists.where!('radiostation_id = ?', params[:radiostation_id]) if params[:radiostation_id].present?
    playlists.where!('generalplaylists.created_at > ?', start_time)
    playlists.where!('generalplaylists.created_at < ?', end_time)
    playlists.uniq
  end

  private

  def today_unique_playlist_item
    exisiting_record = Generalplaylist.joins(:song, :radiostation).where('broadcast_timestamp = ? AND radiostations.id = ?', broadcast_timestamp, radiostation_id).present?
    errors.add(:base, 'none unique playlist') if exisiting_record
  end
end
