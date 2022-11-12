# frozen_string_literal: true

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
