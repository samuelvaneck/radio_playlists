require 'faker'

FactoryBot.define do
  factory :radiostation do
    name { Faker::Name.name }
    genre { Faker::Name.first_name }
  end
end
