require 'faker'

FactoryBot.define do
  factory :generalplaylist do
    time { Faker::Time.between(DateTime.now - 1, DateTime.now).strftime("%H:%M") }
    artist { create :artist }
    song { create :song }
    radiostation { create :radiostation }
    created_at { Faker::Time.between(1.year.ago, Date.today, :all) }
  end
end
