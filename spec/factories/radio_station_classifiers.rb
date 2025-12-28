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
    danceability_average { 0.65 }
    high_danceability_percentage { 0.72 }      # threshold: 0.5
    energy_average { 0.72 }
    high_energy_percentage { 0.80 }            # threshold: 0.5
    speechiness_average { 0.08 }
    high_speechiness_percentage { 0.15 }       # threshold: 0.33 (more tracks pass this lower threshold)
    acousticness_average { 0.25 }
    high_acousticness_percentage { 0.18 }      # threshold: 0.5
    instrumentalness_average { 0.02 }
    high_instrumentalness_percentage { 0.03 }  # threshold: 0.5
    liveness_average { 0.12 }
    high_liveness_percentage { 0.02 }          # threshold: 0.8 (very few tracks pass this high threshold)
    valence_average { 0.58 }
    high_valence_percentage { 0.65 }           # threshold: 0.5
    tempo { 120.5 }
    counter { 100 }
    day_part { 'morning' }
  end
end
