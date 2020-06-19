# frozen_string_literal: true

FactoryBot.define do
  factory :song do
    title { Faker::Music::UmphreysMcgee.song }
    # fullname { Faker::Book.title }

    after(:build) do |song|
      song.fullname = "#{song.artists.map(&:name).join(' ')} #{song.fullname}"
    end

    trait :filled do
      after(:build) do |song|
        song.artists << FactoryBot.create(:artist) if song.artists.blank?
        song.fullname = "#{song.artists.map(&:name).join(' ')} #{song.fullname}"
      end
    end
  end
end
