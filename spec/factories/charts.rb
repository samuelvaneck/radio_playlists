# frozen_string_literal: true

# == Schema Information
#
# Table name: charts
#
#  id         :bigint           not null, primary key
#  date       :date
#  chart_type :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

FactoryBot.define do
  factory :chart do
    date { 1.day.ago }
    chart_type { ['songs', 'artists'].sample }
  end
end
