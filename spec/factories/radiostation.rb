# frozen_string_literal: true

FactoryBot.define do
  factory :radiostation do
    name { Faker::Name.name }
  end
end