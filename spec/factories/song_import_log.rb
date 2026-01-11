# frozen_string_literal: true

FactoryBot.define do
  factory :song_import_log do
    radio_station
    broadcasted_at { Time.zone.now }
    status { :pending }

    trait :with_recognition do
      recognized_artist { Faker::Music.band }
      recognized_title { Faker::Music::RockBand.song }
      recognized_isrc { "US#{Faker::Alphanumeric.alphanumeric(number: 9).upcase}" }
      import_source { :recognition }
    end

    trait :with_acoustid do
      acoustid_artist { Faker::Music.band }
      acoustid_title { Faker::Music::RockBand.song }
      acoustid_recording_id { SecureRandom.uuid }
      acoustid_score { rand(0.7..1.0).round(4) }
    end

    trait :with_scraping do
      scraped_artist { Faker::Music.band }
      scraped_title { Faker::Music::RockBand.song }
      import_source { :scraping }
    end

    trait :with_spotify do
      spotify_artist { Faker::Music.band }
      spotify_title { Faker::Music::RockBand.song }
      spotify_track_id { Faker::Alphanumeric.alphanumeric(number: 22) }
      spotify_isrc { "US#{Faker::Alphanumeric.alphanumeric(number: 9).upcase}" }
    end

    trait :success do
      status { :success }
      song
      air_play
    end

    trait :failed do
      status { :failed }
      failure_reason { 'No matching song found' }
    end

    trait :skipped do
      status { :skipped }
      failure_reason { 'No artist name found' }
    end

    trait :old do
      created_at { 2.days.ago }
    end
  end
end
