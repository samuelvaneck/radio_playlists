# frozen_string_literal: true

FactoryBot.define do
  factory :generalplaylist do
    time { Faker::Time.between(from: DateTime.now - 1, to: DateTime.now).strftime('%H:%M') }
  end

  trait :filled do
    after(:build) do |generalplaylist|
      generalplaylist.radiostation = generalplaylist.radiostation || FactoryBot.build(:radiostation)
      generalplaylist.artist = generalplaylist.artist.present? ? generalplaylist.artist : FactoryBot.create(:artist)
      generalplaylist.song = generalplaylist.song || FactoryBot.create(:song, artist: generalplaylist.artist)
    end
  end
end