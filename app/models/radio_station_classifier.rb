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

  # Thresholds based on Spotify's documentation for what constitutes "high" values
  # https://developer.spotify.com/documentation/web-api/reference/get-audio-features
  HIGH_VALUE_THRESHOLDS = {
    danceability: 0.5,      # Above average danceability
    energy: 0.5,            # Above average energy
    speechiness: 0.33,      # Spotify: 0.33-0.66 = music+speech, >0.66 = speech-only
    acousticness: 0.5,      # Above average acoustic confidence
    instrumentalness: 0.5,  # Spotify: >0.5 likely instrumental
    liveness: 0.8,          # Spotify: >0.8 strong likelihood of live
    valence: 0.5            # Above average positiveness (happy)
  }.freeze

  ATTRIBUTE_DESCRIPTIONS = {
    danceability_average: {
      name: 'Average Danceability',
      description: 'The average danceability score across all tracks played during this day part. ' \
                   'Danceability describes how suitable a track is for dancing based on tempo, rhythm stability, ' \
                   'beat strength, and overall regularity. Higher values indicate more danceable music.',
      range: '0.0 - 1.0'
    },
    high_danceability_percentage: {
      name: 'High Danceability Rate',
      description: 'The percentage of tracks with danceability above 0.5 (considered highly danceable). ' \
                   'A value of 0.75 means 75% of tracks played during this day part are highly danceable.',
      range: '0.0 - 1.0 (percentage)',
      threshold: 0.5
    },
    energy_average: {
      name: 'Average Energy',
      description: 'The average energy score across all tracks. Energy represents intensity and activity - ' \
                   'energetic tracks feel fast, loud, and noisy (like death metal), while low energy tracks ' \
                   'are calmer (like a Bach prelude). Based on dynamic range, loudness, timbre, and onset rate.',
      range: '0.0 - 1.0'
    },
    high_energy_percentage: {
      name: 'High Energy Rate',
      description: 'The percentage of tracks with energy above 0.5 (considered high energy). ' \
                   'A value of 0.80 means 80% of tracks played during this day part are high energy.',
      range: '0.0 - 1.0 (percentage)',
      threshold: 0.5
    },
    speechiness_average: {
      name: 'Average Speechiness',
      description: 'The average speechiness score detecting spoken words in tracks. Values above 0.66 indicate ' \
                   'tracks made entirely of spoken words (talk shows, podcasts). Values between 0.33-0.66 ' \
                   'indicate mixed content (rap, spoken intros). Values below 0.33 indicate mostly music.',
      range: '0.0 - 1.0'
    },
    high_speechiness_percentage: {
      name: 'Speech Content Rate',
      description: 'The percentage of tracks with speechiness above 0.33 (contains speech or mixed content). ' \
                   'Based on Spotify threshold where >0.33 indicates speech presence in the track.',
      range: '0.0 - 1.0 (percentage)',
      threshold: 0.33
    },
    acousticness_average: {
      name: 'Average Acousticness',
      description: 'The average confidence that tracks are acoustic. A value near 1.0 indicates high confidence ' \
                   'that tracks use acoustic instruments (guitars, pianos, strings). A value near 0.0 indicates ' \
                   'electronic or electric instrument-heavy programming.',
      range: '0.0 - 1.0'
    },
    high_acousticness_percentage: {
      name: 'High Acousticness Rate',
      description: 'The percentage of tracks that are likely acoustic (acousticness > 0.5). ' \
                   'Higher values indicate more unplugged, acoustic-focused programming.',
      range: '0.0 - 1.0 (percentage)',
      threshold: 0.5
    },
    instrumentalness_average: {
      name: 'Average Instrumentalness',
      description: 'The average prediction of whether tracks contain no vocals. "Ooh" and "aah" sounds are ' \
                   'treated as instrumental. Higher values indicate more instrumental music without vocals.',
      range: '0.0 - 1.0'
    },
    high_instrumentalness_percentage: {
      name: 'Instrumental Track Rate',
      description: 'The percentage of tracks that are likely instrumental (instrumentalness > 0.5). ' \
                   'Based on Spotify threshold where >0.5 indicates likely instrumental content.',
      range: '0.0 - 1.0 (percentage)',
      threshold: 0.5
    },
    liveness_average: {
      name: 'Average Liveness',
      description: 'The average probability that tracks were performed live with an audience. ' \
                   'Values above 0.8 strongly suggest live recordings.',
      range: '0.0 - 1.0'
    },
    high_liveness_percentage: {
      name: 'Live Recording Rate',
      description: 'The percentage of tracks that are likely live recordings (liveness > 0.8). ' \
                   'Based on Spotify threshold where >0.8 provides strong likelihood of live performance.',
      range: '0.0 - 1.0 (percentage)',
      threshold: 0.8
    },
    valence_average: {
      name: 'Average Valence (Mood)',
      description: 'The average musical positiveness of tracks. High valence (near 1.0) sounds happy, cheerful, ' \
                   'and euphoric. Low valence (near 0.0) sounds sad, depressed, or angry. ' \
                   'This reflects the overall mood of the station during this day part.',
      range: '0.0 - 1.0'
    },
    high_valence_percentage: {
      name: 'Positive Mood Rate',
      description: 'The percentage of tracks with positive mood (valence > 0.5). ' \
                   'Higher values indicate more upbeat, happy programming.',
      range: '0.0 - 1.0 (percentage)',
      threshold: 0.5
    },
    tempo: {
      name: 'Average Tempo',
      description: 'The average tempo of tracks in beats per minute (BPM). Tempo is the speed or pace of music. ' \
                   'Typical ranges: slow ballads (60-80 BPM), pop music (100-130 BPM), dance music (120-150 BPM).',
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
                   'A higher count indicates more reliable and statistically significant values.'
    }
  }.freeze

  belongs_to :radio_station

  def self.attribute_descriptions
    ATTRIBUTE_DESCRIPTIONS
  end
end
