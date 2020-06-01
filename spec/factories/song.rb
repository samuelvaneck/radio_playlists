# frozen_string_literal: true

FactoryBot.define do
  factory :song do
    title { Faker::Music::UmphreysMcgee.song }
    fullname { Faker::Book.title }
  end
end