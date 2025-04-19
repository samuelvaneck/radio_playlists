# frozen_string_literal: true

# == Schema Information
#
# Table name: playlists
#
#  id               :bigint           not null, primary key
#  song_id          :bigint
#  radio_station_id :bigint
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  broadcasted_at   :datetime
#  scraper_import   :boolean          default(FALSE)
#

class Playlist < ApplicationRecord
  include DateConcern

  belongs_to :song
  belongs_to :radio_station
  has_many :artists, through: :song

  scope :scraper_imported, -> { where(scraper_import: true) }
  scope :recognizer_imported, -> { where(scraper_import: false) }
  scope :matching, lambda { |search_term|
    joins(:song, :artists).where('songs.title ILIKE ? OR artists.name ILIKE ?', "%#{search_term}%", "%#{search_term}%") if search_term.present?
  }

  validate :today_unique_playlist_item

  def self.last_played(params = {})
    Playlist.joins(:song)
            .played_between(date_from_params(time: params[:start_time], fallback: 1.day.ago),
                            date_from_params(time: params[:end_time], fallback: Time.zone.now))
            .played_on(params[:radio_station_ids])
            .matching(params[:search_term])
            .group(:id)
            .order(created_at: :desc)
  end

  def deduplicate
    return unless duplicate?

    song = Song.find(song_id)
    destroy
    song.cleanup
  end

  def duplicate?
    Playlist.where(radio_station:, broadcasted_at:).count > 1
  end

  def self.add_playlist(radio_station, song, broadcasted_at, scraper_import)
    create(radio_station:, song:, broadcasted_at:, scraper_import:)
  end

  private

  def today_unique_playlist_item
    exisiting_record = Playlist.joins(:song, :radio_station)
                               .where('broadcasted_at = ? AND radio_stations.id = ?', broadcasted_at, radio_station_id)
                               .present?
    errors.add(:base, 'none unique playlist') if exisiting_record
  end
end
