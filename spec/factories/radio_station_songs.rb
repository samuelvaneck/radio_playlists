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
FactoryBot.define do
  factory :radio_station_song do
    song { build(:song) }
    radio_station { build(:radio_station) }
    first_broadcasted_at { 1.week.ago }
  end
end
