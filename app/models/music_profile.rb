# frozen_string_literal: true

# == Schema Information
#
# Table name: music_profiles
#
#  id               :bigint           not null, primary key
#  acousticness     :decimal(5, 4)
#  danceability     :decimal(5, 4)
#  energy           :decimal(5, 4)
#  instrumentalness :decimal(5, 4)
#  liveness         :decimal(5, 4)
#  speechiness      :decimal(5, 4)
#  tempo            :decimal(6, 2)
#  valence          :decimal(5, 4)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  song_id          :bigint           not null
#
# Indexes
#
#  index_music_profiles_on_song_id  (song_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (song_id => songs.id)
#
class MusicProfile < ApplicationRecord
  AUDIO_FEATURES = %w[danceability energy speechiness acousticness instrumentalness liveness valence].freeze

  # Thresholds based on Spotify's documentation for what constitutes "high" values
  # https://developer.spotify.com/documentation/web-api/reference/get-audio-features
  HIGH_VALUE_THRESHOLDS = {
    danceability: 0.5,
    energy: 0.5,
    speechiness: 0.33,
    acousticness: 0.5,
    instrumentalness: 0.5,
    liveness: 0.8,
    valence: 0.5
  }.freeze

  ATTRIBUTE_DESCRIPTIONS = {
    danceability: {
      name: 'Danceability',
      description: 'How suitable the track is for dancing based on tempo, rhythm stability, ' \
                   'beat strength, and overall regularity. Higher values indicate more danceable music.',
      range: '0.0 - 1.0',
      threshold: 0.5
    },
    energy: {
      name: 'Energy',
      description: 'Intensity and activity level. Energetic tracks feel fast, loud, and noisy ' \
                   '(like death metal), while low energy tracks are calmer (like a Bach prelude).',
      range: '0.0 - 1.0',
      threshold: 0.5
    },
    speechiness: {
      name: 'Speechiness',
      description: 'Presence of spoken words in the track. Values above 0.66 indicate tracks made ' \
                   'entirely of spoken words. Values between 0.33-0.66 indicate mixed content (rap, spoken intros).',
      range: '0.0 - 1.0',
      threshold: 0.33
    },
    acousticness: {
      name: 'Acousticness',
      description: 'Confidence that the track is acoustic. A value near 1.0 indicates high confidence ' \
                   'that the track uses acoustic instruments.',
      range: '0.0 - 1.0',
      threshold: 0.5
    },
    instrumentalness: {
      name: 'Instrumentalness',
      description: 'Prediction of whether the track contains no vocals. Higher values indicate more ' \
                   'instrumental music without vocals.',
      range: '0.0 - 1.0',
      threshold: 0.5
    },
    liveness: {
      name: 'Liveness',
      description: 'Probability that the track was performed live with an audience. ' \
                   'Values above 0.8 strongly suggest live recordings.',
      range: '0.0 - 1.0',
      threshold: 0.8
    },
    valence: {
      name: 'Valence (Mood)',
      description: 'Musical positiveness of the track. High valence sounds happy, cheerful, and euphoric. ' \
                   'Low valence sounds sad, depressed, or angry.',
      range: '0.0 - 1.0',
      threshold: 0.5
    },
    tempo: {
      name: 'Tempo',
      description: 'The tempo of the track in beats per minute (BPM). ' \
                   'Typical ranges: slow ballads (60-80 BPM), pop music (100-130 BPM), dance music (120-150 BPM).',
      range: '0 - 250 BPM'
    }
  }.freeze

  belongs_to :song

  validates :song_id, uniqueness: true

  def self.attribute_descriptions
    ATTRIBUTE_DESCRIPTIONS
  end

  def high_feature?(feature)
    threshold = HIGH_VALUE_THRESHOLDS[feature.to_sym]
    return false if threshold.nil?

    value = send(feature)
    return false if value.nil?

    value > threshold
  end
end
