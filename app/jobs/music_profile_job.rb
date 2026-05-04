# frozen_string_literal: true

class MusicProfileJob
  include Sidekiq::Job
  sidekiq_options queue: 'enrichment'

  def perform(song_id, radio_station_id = nil)
    song = Song.find_by(id: song_id)
    return if song.blank? || song.id_on_spotify.blank?

    # Skip if profile already exists (idempotent)
    return if song.music_profile.present?

    audio_features = fetch_audio_features(song.id_on_spotify)
    return if audio_features.blank?

    music_profile = create_music_profile(song, audio_features)
    update_hit_potential_score(song, music_profile)

    # Keep genre tagging logic (moved from RadioStationClassifierJob)
    update_radio_station_tags(song.id_on_spotify, radio_station_id) if radio_station_id.present?

    Rails.logger.info "MusicProfile created for song #{song_id}"
  end

  private

  def fetch_audio_features(id_on_spotify)
    Spotify::AudioFeature.new(id_on_spotify:).audio_features
  end

  def update_hit_potential_score(song, _music_profile)
    score = HitPotentialCalculator.new(song).calculate
    song.update_column(:hit_potential_score, score) if score.present? # rubocop:disable Rails/SkipsModelValidations
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
      tempo: audio_features['tempo'],
      key: audio_features['key'],
      mode: audio_features['mode'],
      loudness: audio_features['loudness'],
      time_signature: audio_features['time_signature']
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
      update_artist_from_spotify(artist['id'], spotify_artist)
      spotify_artist['genres']
    end.uniq
  end

  def update_artist_from_spotify(id_on_spotify, spotify_artist)
    return if spotify_artist.blank?

    artist = Artist.find_by(id_on_spotify:)
    return if artist.blank?

    updates = {}
    updates[:genres] = spotify_artist['genres'] if artist.genres.blank? && spotify_artist['genres'].present?
    updates[:spotify_popularity] = spotify_artist['popularity'] if spotify_artist['popularity'].present?
    updates[:spotify_followers_count] = spotify_artist.dig('followers', 'total') if spotify_artist.dig('followers', 'total').present?
    artist.update(updates) if updates.present?
  end
end
