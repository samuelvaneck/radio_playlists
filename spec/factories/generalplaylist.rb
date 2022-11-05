# frozen_string_literal: true

FactoryBot.define do
  factory :generalplaylist do
    broadcast_timestamp { Faker::Time.between(from: DateTime.now - 1, to: DateTime.now) }
  end

  trait :filled do
    after(:build) do |generalplaylist|
      generalplaylist.radio_station ||= FactoryBot.build(:radio_station)
      generalplaylist.song ||= FactoryBot.create(:song, :filled)
    end
  end
end
