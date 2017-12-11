require 'faker'

FactoryBot.define do
  factory :song do
    title { Faker::Name.name }
    artist { create :artist }
  end
end
