class RadioStationClassifierJob
  include Sidekiq::Job
  sidekiq_options queue: 'low'

  AUDIO_FEATURES = %w[danceability energy speechiness acousticness instrumentalness liveness valence].freeze

  def perform(id_on_spotify, radio_station_id)
    return if id_on_spotify.blank?

    audio_features = fetch_audio_features(id_on_spotify)
    classifier = find_or_initialize_classifier(radio_station_id)

    update_classifier_with_audio_features(classifier, audio_features)
    classifier.tempo = ((classifier.tempo * classifier.counter) + audio_features['tempo']) / (classifier.counter + 1)
    classifier.counter += 1
    classifier.save

    update_radio_station_tags(id_on_spotify: id_on_spotify, radio_station_id: radio_station_id)
    Rails.logger.info "Radio station classifier for radio station #{radio_station_id} updated"
  end
  private

  def fetch_audio_features(id_on_spotify)
    Spotify::AudioFeature.new(id_on_spotify: id_on_spotify).get_audio_features
  end

  def find_or_initialize_classifier(radio_station_id)
    RadioStationClassifier.lock.find_or_initialize_by(
      radio_station_id: radio_station_id,
      day_part: day_part(Time.now)
    )
  end

  def update_classifier_with_audio_features(classifier, audio_features)
    AUDIO_FEATURES.each do |feature|
      classifier[feature] += 1 if audio_features[feature] > 0.5
      classifier["#{feature}_average"] = ((classifier["#{feature}_average"] * classifier.counter) + audio_features[feature]) / (classifier.counter + 1)
    end
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
    track = ::Spotify::Track::FindById.new(id_on_spotify: args[:id_on_spotify]).execute
    track['artists'].flat_map do |artist|
      spotify_artist = Spotify::Artist.new(id_on_spotify: artist['id']).info
      spotify_artist['genres']
    end.uniq
  end

  def audio_feature_to_classifier(feature)
    case feature
    when 'danceability'
      :danceable
    when 'energy'
      :energy
    when 'speechiness'
      :speech
    when 'acousticness'
      :acoustic
    when 'instrumentalness'
      :instrumental
    when 'liveness'
      :live
    when 'valence'
      :valence
    end
  end
end
