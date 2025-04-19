# == Schema Information
#
# Table name: radio_station_songs
#
#  id                   :bigint           not null, primary key
#  song_id              :bigint           not null
#  radio_station_id     :bigint           not null
#  first_broadcasted_at :datetime
#
FactoryBot.define do
  factory :radio_station_song do
    song { build(:song) }
    radio_station { build(:radio_station) }
    first_broadcasted_at { 1.week.ago }
  end
end
