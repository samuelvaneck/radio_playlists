class RadioStationClassifierJob
  AUDIO_FEATURES = %w[danceability energy speechiness acousticness instrumentalness liveness valence].freeze

  # Thresholds based on Spotify's documentation for what constitutes "high" values
  # https://developer.spotify.com/documentation/web-api/reference/get-audio-features
  HIGH_VALUE_THRESHOLDS = {
    'danceability' => 0.5,      # Above average danceability
    'energy' => 0.5,            # Above average energy
    'speechiness' => 0.33,      # Spotify: 0.33-0.66 = music+speech, >0.66 = speech-only
    'acousticness' => 0.5,      # Above average acoustic confidence
    'instrumentalness' => 0.5,  # Spotify: >0.5 likely instrumental
    'liveness' => 0.8,          # Spotify: >0.8 strong likelihood of live
    'valence' => 0.5            # Above average positiveness (happy)
  }.freeze

  include Sidekiq::Job
  sidekiq_options queue: 'low'

  def perform(id_on_spotify, radio_station_id)
    return if id_on_spotify.blank?

    audio_features = fetch_audio_features(id_on_spotify)
    return if audio_features.blank?

    classifier = find_or_initialize_classifier(radio_station_id)

    update_classifier_with_audio_features(classifier, audio_features)
    update_tempo(classifier, audio_features)
    classifier.counter += 1
    classifier.save

    update_radio_station_tags(id_on_spotify: id_on_spotify, radio_station_id: radio_station_id)
    Rails.logger.info "Radio station classifier for radio station #{radio_station_id} updated"
  end

  private

  def fetch_audio_features(id_on_spotify)
    Spotify::AudioFeature.new(id_on_spotify: id_on_spotify).audio_features
  end

  def find_or_initialize_classifier(radio_station_id)
    RadioStationClassifier.lock.find_or_initialize_by(radio_station_id:, day_part: day_part(Time.zone.now))
  end

  def update_classifier_with_audio_features(classifier, audio_features)
    AUDIO_FEATURES.each do |feature|
      next if audio_features[feature].nil?

      # Update running average for the feature
      average = running_average(classifier["#{feature}_average"], audio_features[feature], classifier.counter)
      classifier["#{feature}_average"] = average

      # Update percentage of tracks exceeding the feature-specific threshold
      high_percentage_column = "high_#{feature}_percentage"
      threshold = HIGH_VALUE_THRESHOLDS[feature]
      is_high_value = audio_features[feature] > threshold ? 1.0 : 0.0
      classifier[high_percentage_column] = running_average(classifier[high_percentage_column], is_high_value, classifier.counter)
    end
  end

  def update_tempo(classifier, audio_features)
    return if audio_features['tempo'].nil?

    classifier.tempo = running_average(classifier.tempo, audio_features['tempo'], classifier.counter)
  end

  # Calculate running average: ((old_avg * count) + new_value) / (count + 1)
  def running_average(current_average, new_value, current_count)
    ((current_average * current_count) + new_value) / (current_count + 1)
  end

  def update_radio_station_tags(args)
    tags = track_artists_tags(args)
    radio_station = RadioStation.find(args[:radio_station_id])

    tags.each do |tag|
      tag = Tag.find_or_initialize_by(name: tag, taggable: radio_station)
      tag.counter += 1
      tag.save
    end
  end

  def day_part(time)
    case time.try(:hour)
    when NilClass
      nil
    when 0..5
      :night
    when 6..9
      :breakfast
    when 10..11
      :morning
    when 12..12
      :lunch
    when 13..15
      :afternoon
    when 16..19
      :dinner
    when 20..23
      :evening
    end
  end

  def track_artists_tags(args)
    track = ::Spotify::TrackFinder::FindById.new(id_on_spotify: args[:id_on_spotify]).execute
    track['artists'].flat_map do |artist|
      spotify_artist = Spotify::ArtistFinder.new(id_on_spotify: artist['id']).info
      spotify_artist['genres']
    end.uniq
  end
end
