# frozen_string_literal: true

# == Schema Information
#
# Table name: charts
#
#  id         :bigint           not null, primary key
#  chart_type :string
#  date       :date
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_charts_on_date  (date)
#

FactoryBot.define do
  factory :chart do
    date { 1.day.ago }
    chart_type { ['songs', 'artists'].sample }
  end
end
