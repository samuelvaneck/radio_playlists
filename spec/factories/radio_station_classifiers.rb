# == Schema Information
#
# Table name: radio_station_classifiers
#
#  id                       :bigint           not null, primary key
#  radio_station_id         :bigint           not null
#  day_part                 :string           not null
#  danceability             :integer          default(0)
#  danceability_average     :decimal(5, 3)    default(0.0)
#  energy                   :integer          default(0)
#  energy_average           :decimal(5, 3)    default(0.0)
#  speechiness              :integer          default(0)
#  speechiness_average      :decimal(5, 3)    default(0.0)
#  acousticness             :integer          default(0)
#  acousticness_average     :decimal(5, 3)    default(0.0)
#  instrumentalness         :integer          default(0)
#  instrumentalness_average :decimal(5, 3)    default(0.0)
#  liveness                 :integer          default(0)
#  liveness_average         :decimal(5, 3)    default(0.0)
#  valence                  :integer          default(0)
#  valence_average          :decimal(5, 3)    default(0.0)
#  tempo                    :decimal(5, 2)    default(0.0)
#  counter                  :integer          default(0)
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#
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
