# frozen_string_literal: true

# == Schema Information
#
# Table name: air_plays
#
#  id               :bigint           not null, primary key
#  broadcasted_at   :datetime
#  scraper_import   :boolean          default(FALSE)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  radio_station_id :bigint
#  song_id          :bigint
#
# Indexes
#
#  index_air_plays_on_radio_station_id  (radio_station_id)
#  index_air_plays_on_song_id           (song_id)
#  air_play_radio_song_time             (song_id,radio_station_id,broadcasted_at) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (radio_station_id => radio_stations.id)
#  fk_rails_...  (song_id => songs.id)
#

class AirPlay < ApplicationRecord
  include DateConcern

  belongs_to :song
  belongs_to :radio_station
  has_many :artists, through: :song

  scope :scraper_imported, -> { where(scraper_import: true) }
  scope :recognizer_imported, -> { where(scraper_import: false) }
  scope :matching, lambda { |search_term|
    joins(:song).where('songs.search_text ILIKE ?', "%#{search_term}%") if search_term.present?
  }

  validate :today_unique_air_play_item

  def self.last_played(params = {})
    AirPlay.joins(:song, :radio_station)
           .played_between(date_from_params(time: params[:start_time], fallback: 1.day.ago),
                           date_from_params(time: params[:end_time], fallback: Time.zone.now))
           .played_on(params[:radio_station_ids])
           .matching(params[:search_term])
           .group(:id, 'songs.id', 'radio_stations.id')
           .order(created_at: :desc)
  end

  def deduplicate
    return unless duplicate?

    song = Song.find(song_id)
    destroy
    song.cleanup
  end

  def duplicate?
    AirPlay.where(radio_station:, broadcasted_at:).count > 1
  end

  def self.add_air_play(radio_station, song, broadcasted_at, scraper_import)
    create(radio_station:, song:, broadcasted_at:, scraper_import:)
  end

  private

  def today_unique_air_play_item
    exisiting_record = AirPlay.joins(:song, :radio_station)
                              .where('broadcasted_at = ? AND radio_stations.id = ?', broadcasted_at, radio_station_id)
                              .present?
    errors.add(:base, 'none unique air play') if exisiting_record
  end
end
