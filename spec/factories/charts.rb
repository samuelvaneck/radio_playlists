# frozen_string_literal: true

FactoryBot.define do
  factory :chart do
    date { 1.day.ago }
    chart { [] }
    chart_type { ['songs', 'artists'].sample }
  end
end
