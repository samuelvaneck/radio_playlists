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

class Playlist < ApplicationRecord
  belongs_to :song
  belongs_to :radio_station
  has_many :artists, through: :song

  scope :scraper_imported, -> { where(scraper_import: true) }
  scope :recognizer_imported, -> { where(scraper_import: false) }
  scope :matching, lambda { |search_term|
    joins(:artists, song: [:artists]).where('songs.title ILIKE ? OR artists.name ILIKE ?', "%#{search_term}%", "%#{search_term}%") if search_term
  }

  validate :today_unique_playlist_item

  def self.last_played(params)
    Playlist.played_between(parsed_time(time: params[:start_time], fallback: 1.day.ago),
                            parsed_time(time: params[:end_time], fallback: Time.zone.now))
            .played_on(parsed_radio_station(params[:radio_station_id]))
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
    Playlist.where(radio_station:, broadcast_timestamp:).count > 1
  end

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
