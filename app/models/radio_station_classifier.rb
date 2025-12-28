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
class RadioStationClassifier < ApplicationRecord
  DAY_PARTS = %w[night breakfast morning lunch afternoon dinner evening].freeze

  ATTRIBUTE_DESCRIPTIONS = {
    danceability: {
      name: 'Danceability',
      description: 'Describes how suitable a track is for dancing based on a combination of musical elements ' \
                   'including tempo, rhythm stability, beat strength, and overall regularity. ' \
                   'A value of 0.0 is least danceable and 1.0 is most danceable.',
      range: '0.0 - 1.0'
    },
    energy: {
      name: 'Energy',
      description: 'Represents a perceptual measure of intensity and activity. Typically, energetic tracks feel ' \
                   'fast, loud, and noisy. For example, death metal has high energy, while a Bach prelude scores ' \
                   'low on the scale. Perceptual features contributing to this attribute include dynamic range, ' \
                   'perceived loudness, timbre, onset rate, and general entropy.',
      range: '0.0 - 1.0'
    },
    speechiness: {
      name: 'Speechiness',
      description: 'Detects the presence of spoken words in a track. The more exclusively speech-like the ' \
                   'recording (e.g. talk show, audio book, poetry), the closer to 1.0 the attribute value. ' \
                   'Values above 0.66 describe tracks that are probably made entirely of spoken words. ' \
                   'Values between 0.33 and 0.66 describe tracks that may contain both music and speech. ' \
                   'Values below 0.33 most likely represent music and other non-speech-like tracks.',
      range: '0.0 - 1.0'
    },
    acousticness: {
      name: 'Acousticness',
      description: 'A confidence measure of whether the track is acoustic. A value of 1.0 represents high ' \
                   'confidence the track is acoustic (uses acoustic instruments like guitars, pianos, strings). ' \
                   'A value of 0.0 represents high confidence the track is electronic or uses electric instruments.',
      range: '0.0 - 1.0'
    },
    instrumentalness: {
      name: 'Instrumentalness',
      description: 'Predicts whether a track contains no vocals. "Ooh" and "aah" sounds are treated as ' \
                   'instrumental in this context. Rap or spoken word tracks are clearly "vocal". ' \
                   'The closer the instrumentalness value is to 1.0, the greater likelihood the track ' \
                   'contains no vocal content. Values above 0.5 are intended to represent instrumental tracks.',
      range: '0.0 - 1.0'
    },
    liveness: {
      name: 'Liveness',
      description: 'Detects the presence of an audience in the recording. Higher liveness values represent ' \
                   'an increased probability that the track was performed live. A value above 0.8 provides ' \
                   'strong likelihood that the track is live.',
      range: '0.0 - 1.0'
    },
    valence: {
      name: 'Valence',
      description: 'A measure describing the musical positiveness conveyed by a track. Tracks with high valence ' \
                   'sound more positive (e.g. happy, cheerful, euphoric), while tracks with low valence sound ' \
                   'more negative (e.g. sad, depressed, angry).',
      range: '0.0 - 1.0'
    },
    tempo: {
      name: 'Tempo',
      description: 'The overall estimated tempo of a track in beats per minute (BPM). In musical terminology, ' \
                   'tempo is the speed or pace of a given piece and derives directly from the average beat duration.',
      range: '0 - 250 BPM'
    },
    day_part: {
      name: 'Day Part',
      description: 'The time segment of the day when these audio characteristics were measured. ' \
                   'Night (00:00-05:59), Breakfast (06:00-09:59), Morning (10:00-11:59), ' \
                   'Lunch (12:00-12:59), Afternoon (13:00-15:59), Dinner (16:00-19:59), Evening (20:00-23:59).',
      values: DAY_PARTS
    },
    counter: {
      name: 'Sample Count',
      description: 'The total number of songs analyzed to calculate the average values for this day part. ' \
                   'A higher count indicates more reliable average values.'
    }
  }.freeze

  belongs_to :radio_station

  def self.attribute_descriptions
    ATTRIBUTE_DESCRIPTIONS
  end
end
