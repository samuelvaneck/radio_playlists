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
class RadioStationClassifierSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id,
             :radio_station,
             :day_part,
             :danceability,
             :danceability_average,
             :energy,
             :energy_average,
             :speechiness,
             :speechiness_average,
             :acousticness,
             :acousticness_average,
             :instrumentalness,
             :instrumentalness_average,
             :liveness,
             :liveness_average,
             :valence,
             :valence_average,
             :tempo

  def radio_station
    RadioStationSerializer.new(object.radio_station)
  end
end
