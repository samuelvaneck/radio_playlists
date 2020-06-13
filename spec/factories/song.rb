# frozen_string_literal: true

FactoryBot.define do
  factory :song do
    title { Faker::Music::UmphreysMcgee.song }
    fullname { Faker::Book.title }

    trait :filled do
      after(:build) do |song|
        song.artists << FactoryBot.create(:artist) if song.artists.blank?
      end
    end
  end
end
