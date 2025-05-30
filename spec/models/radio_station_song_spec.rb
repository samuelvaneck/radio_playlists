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
#  index_radio_station_songs_on_radio_station_id              (radio_station_id)
#  index_radio_station_songs_on_song_id                       (song_id)
#  index_radio_station_songs_on_song_id_and_radio_station_id  (song_id,radio_station_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (radio_station_id => radio_stations.id)
#  fk_rails_...  (song_id => songs.id)
#
require 'rails_helper'

RSpec.describe RadioStationSong, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:song) }
    it { is_expected.to belong_to(:radio_station) }
  end
end
