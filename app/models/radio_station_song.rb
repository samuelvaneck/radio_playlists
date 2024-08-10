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
  belongs_to :song
  belongs_to :radio_station

  before_save :set_first_broadcasted_at

  private def set_first_broadcasted_at
    self.first_broadcasted_at = Time.current
  end
end
