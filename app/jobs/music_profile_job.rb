# frozen_string_literal: true

class MusicProfileJob
  include Sidekiq::Job
  sidekiq_options queue: 'low'

  def perform(song_id, radio_station_id = nil)
    song = Song.find_by(id: song_id)
    return if song.blank? || song.id_on_spotify.blank?

    # Skip if profile already exists (idempotent)
    return if song.music_profile.present?

    audio_features = fetch_audio_features(song.id_on_spotify)
    return if audio_features.blank?

    create_music_profile(song, audio_features)

    # Keep genre tagging logic (moved from RadioStationClassifierJob)
    update_radio_station_tags(song.id_on_spotify, radio_station_id) if radio_station_id.present?

    Rails.logger.info "MusicProfile created for song #{song_id}"
  end

  private

  def fetch_audio_features(id_on_spotify)
    Spotify::AudioFeature.new(id_on_spotify:).audio_features
  end

  def create_music_profile(song, audio_features)
    MusicProfile.create!(
      song:,
      danceability: audio_features['danceability'],
      energy: audio_features['energy'],
      speechiness: audio_features['speechiness'],
      acousticness: audio_features['acousticness'],
      instrumentalness: audio_features['instrumentalness'],
      liveness: audio_features['liveness'],
      valence: audio_features['valence'],
      tempo: audio_features['tempo']
    )
  end

  def update_radio_station_tags(id_on_spotify, radio_station_id)
    tags = track_artists_tags(id_on_spotify)
    radio_station = RadioStation.find(radio_station_id)

    tags.each do |tag|
      tag_record = Tag.find_or_initialize_by(name: tag, taggable: radio_station)
      tag_record.counter += 1
      tag_record.save
    end
  end

  def track_artists_tags(id_on_spotify)
    track = Spotify::TrackFinder::FindById.new(id_on_spotify:).execute
    track['artists'].flat_map do |artist|
      spotify_artist = Spotify::ArtistFinder.new(id_on_spotify: artist['id']).info
      spotify_artist['genres']
    end.uniq
  end
end
