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
    song { nil }
    radio_station { nil }
    first_broadcasted_at { "2024-08-10 16:06:10" }
  end
end
