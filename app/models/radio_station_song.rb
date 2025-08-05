# == Schema Information
#
# Table name: radio_station_songs
#
#  id                   :bigint           not null, primary key
#  first_broadcasted_at :datetime
#  radio_station_id     :bigint           not null
#  song_id              :bigint           not null
#
# Indexes
#
#  index_radio_station_songs_on_first_broadcasted_at          (first_broadcasted_at)
#  index_radio_station_songs_on_radio_station_id              (radio_station_id)
#  index_radio_station_songs_on_song_id                       (song_id)
#  index_radio_station_songs_on_song_id_and_radio_station_id  (song_id,radio_station_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (radio_station_id => radio_stations.id)
#  fk_rails_...  (song_id => songs.id)
#

class RadioStationSong < ApplicationRecord
  before_create :set_first_broadcasted_at, if: -> { first_broadcasted_at.blank? }

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
    song.playlists.where(radio_station_id:).minimum(:broadcasted_at)
  end
end
