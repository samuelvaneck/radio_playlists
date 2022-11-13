# frozen_string_literal: true

FactoryBot.define do
  factory :song do
    title { Faker::Music::UmphreysMcgee.song }
    isrc_id { 'GBARL1800805' }
    id_on_spotify { '1elj43HiTzMyQwawBazPCQ' }

    after(:build) do |song|
      song.fullname = "#{song.artists.map(&:name).join(' ')} #{song.fullname}"
    end

    trait :filled do
      after(:build) do |song|
        song.artists << create(:artist) if song.artists.blank?
        song.fullname = "#{song.artists.map(&:name).join(' ')} #{song.fullname}"
      end
    end
  end
end
