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
