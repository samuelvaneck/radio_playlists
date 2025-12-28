# == Schema Information
#
# Table name: radio_station_classifiers
#
#  id                       :bigint           not null, primary key
#  acousticness             :integer          default(0)
#  acousticness_average     :decimal(5, 3)    default(0.0)
#  counter                  :integer          default(0)
#  danceability             :integer          default(0)
#  danceability_average     :decimal(5, 3)    default(0.0)
#  day_part                 :string           not null
#  energy                   :integer          default(0)
#  energy_average           :decimal(5, 3)    default(0.0)
#  instrumentalness         :integer          default(0)
#  instrumentalness_average :decimal(5, 3)    default(0.0)
#  liveness                 :integer          default(0)
#  liveness_average         :decimal(5, 3)    default(0.0)
#  speechiness              :integer          default(0)
#  speechiness_average      :decimal(5, 3)    default(0.0)
#  tempo                    :decimal(5, 2)    default(0.0)
#  valence                  :integer          default(0)
#  valence_average          :decimal(5, 3)    default(0.0)
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  radio_station_id         :bigint           not null
#
# Indexes
#
#  idx_on_radio_station_id_day_part_3fdb6160cd          (radio_station_id,day_part) UNIQUE
#  index_radio_station_classifiers_on_radio_station_id  (radio_station_id)
#
# Foreign Keys
#
#  fk_rails_...  (radio_station_id => radio_stations.id)
#
FactoryBot.define do
  factory :radio_station_classifier do
    radio_station
    danceability { 50 }
    danceability_average { 0.65 }
    energy { 45 }
    energy_average { 0.72 }
    speechiness { 10 }
    speechiness_average { 0.08 }
    acousticness { 20 }
    acousticness_average { 0.25 }
    instrumentalness { 5 }
    instrumentalness_average { 0.02 }
    liveness { 15 }
    liveness_average { 0.12 }
    valence { 40 }
    valence_average { 0.58 }
    tempo { 120.5 }
    counter { 100 }
    day_part { 'morning' }
  end
end
