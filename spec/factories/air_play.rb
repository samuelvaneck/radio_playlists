# frozen_string_literal: true

# == Schema Information
#
# Table name: air_plays
#
#  id               :bigint           not null, primary key
#  song_id          :bigint
#  radio_station_id :bigint
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  broadcasted_at   :datetime
#  scraper_import   :boolean          default(FALSE)
#  status           :integer          default(0)
#

FactoryBot.define do
  factory :air_play, class: 'AirPlay' do
    broadcasted_at { Faker::Time.between(from: DateTime.now - 1, to: DateTime.now) }
    radio_station { create(:radio_station) }
    song { create(:song) }
    status { :confirmed }

    after(:build) do |air_play|
      song = air_play.song
      radio_station = air_play.radio_station
      song.radio_stations << radio_station unless song.radio_stations.include?(radio_station)
    end

    trait :draft do
      status { :draft }
    end

    trait :confirmed do
      status { :confirmed }
    end
  end
end
