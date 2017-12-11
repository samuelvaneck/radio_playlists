require 'faker'

FactoryBot.define do
  factory :artist do
    name { Faker::RockBand.name }
    image { Faker::File.file_name('foo/bar', 'test', 'png') }
    genre { Faker::Name.first_name }
  end
end
