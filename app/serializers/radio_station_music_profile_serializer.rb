# frozen_string_literal: true

class RadioStationMusicProfileSerializer
  AGGREGATED_ATTRIBUTE_DESCRIPTIONS = {
    danceability_average: {
      name: 'Average Danceability',
      description: 'The average danceability score across all tracks played during this day part.',
      range: '0.0 - 1.0'
    },
    high_danceability_percentage: {
      name: 'High Danceability Rate',
      description: 'The percentage of tracks with danceability above 0.5.',
      range: '0.0 - 1.0 (percentage)',
      threshold: 0.5
    },
    energy_average: {
      name: 'Average Energy',
      description: 'The average energy score across all tracks.',
      range: '0.0 - 1.0'
    },
    high_energy_percentage: {
      name: 'High Energy Rate',
      description: 'The percentage of tracks with energy above 0.5.',
      range: '0.0 - 1.0 (percentage)',
      threshold: 0.5
    },
    speechiness_average: {
      name: 'Average Speechiness',
      description: 'The average speechiness score detecting spoken words in tracks.',
      range: '0.0 - 1.0'
    },
    high_speechiness_percentage: {
      name: 'Speech Content Rate',
      description: 'The percentage of tracks with speechiness above 0.33.',
      range: '0.0 - 1.0 (percentage)',
      threshold: 0.33
    },
    acousticness_average: {
      name: 'Average Acousticness',
      description: 'The average confidence that tracks are acoustic.',
      range: '0.0 - 1.0'
    },
    high_acousticness_percentage: {
      name: 'High Acousticness Rate',
      description: 'The percentage of tracks that are likely acoustic.',
      range: '0.0 - 1.0 (percentage)',
      threshold: 0.5
    },
    instrumentalness_average: {
      name: 'Average Instrumentalness',
      description: 'The average prediction of whether tracks contain no vocals.',
      range: '0.0 - 1.0'
    },
    high_instrumentalness_percentage: {
      name: 'Instrumental Track Rate',
      description: 'The percentage of tracks that are likely instrumental.',
      range: '0.0 - 1.0 (percentage)',
      threshold: 0.5
    },
    liveness_average: {
      name: 'Average Liveness',
      description: 'The average probability that tracks were performed live.',
      range: '0.0 - 1.0'
    },
    high_liveness_percentage: {
      name: 'Live Recording Rate',
      description: 'The percentage of tracks that are likely live recordings.',
      range: '0.0 - 1.0 (percentage)',
      threshold: 0.8
    },
    valence_average: {
      name: 'Average Valence (Mood)',
      description: 'The average musical positiveness of tracks.',
      range: '0.0 - 1.0'
    },
    high_valence_percentage: {
      name: 'Positive Mood Rate',
      description: 'The percentage of tracks with positive mood.',
      range: '0.0 - 1.0 (percentage)',
      threshold: 0.5
    },
    tempo: {
      name: 'Average Tempo',
      description: 'The average tempo of tracks in beats per minute (BPM).',
      range: '0 - 250 BPM'
    },
    hour: {
      name: 'Hour',
      description: 'The hour of the day (0-23) when these audio characteristics were measured.',
      values: RadioStationMusicProfileCalculator::HOURS
    },
    counter: {
      name: 'Sample Count',
      description: 'The total number of songs analyzed for this hour.'
    }
  }.freeze

  def initialize(profiles, radio_station: nil)
    @profiles = Array.wrap(profiles)
    @radio_station = radio_station
  end

  def serializable_hash
    {
      data: @profiles.map { |profile| serialize_profile(profile) },
      meta: {
        attribute_descriptions: AGGREGATED_ATTRIBUTE_DESCRIPTIONS,
        radio_station: @radio_station ? { id: @radio_station.id, name: @radio_station.name } : nil
      }.compact
    }
  end

  private

  def serialize_profile(profile)
    {
      type: 'radio_station_music_profile',
      attributes: profile
    }
  end
end
