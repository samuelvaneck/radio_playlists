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
#

FactoryBot.define do
  factory :playlist do
    broadcast_timestamp { Faker::Time.between(from: DateTime.now - 1, to: DateTime.now) }
  end

  trait :filled do
    after(:build) do |playlist|
      playlist.radio_station ||= build(:radio_station)
      playlist.song ||= create(:song, :filled)
    end
  end
end
