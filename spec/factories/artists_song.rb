# frozen_string_literal: true

FactoryBot.define do
  factory :artists_song do
    association :artist, factory: :artist
    association :song, factory: :song
  end
end
