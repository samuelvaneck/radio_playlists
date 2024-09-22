FactoryBot.define do
  factory :radio_station_classifier do
    radio_station { nil }
    danceable { 1 }
    energy { 1 }
    speechs { 1 }
    acoustic { 1 }
    instrumental { 1 }
    live { 1 }
    valance { 1 }
    day_part { "MyString" }
    tags { "" }
  end
end
