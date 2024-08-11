# == Schema Information
#
# Table name: radio_station_songs
#
#  id                   :bigint           not null, primary key
#  song_id              :bigint           not null
#  radio_station_id     :bigint           not null
#  first_broadcasted_at :datetime
#

class RadioStationSong < ApplicationRecord
  before_save :set_first_broadcasted_at

  belongs_to :song
  belongs_to :radio_station

  scope :played_between, ->(start_time, end_time) { where(first_broadcasted_at: start_time..end_time) }
  scope :played_on, lambda { |radio_station_ids|
    return if radio_station_ids.blank?

    radio_station_ids = JSON.parse(radio_station_ids) if radio_station_ids.is_a?(String)
    where(radio_station_id: radio_station_ids)
  }

  private

  def set_first_broadcasted_at
    self.first_broadcasted_at = lookup_first_broadcasted_at
  end

  def lookup_first_broadcasted_at
    song.playlists.find_by(radio_station_id:).broadcasted_at
  end
end
