# frozen_string_literal: true

class HitPotentialCalculator
  # Signal category weights based on multi-signal research:
  # - Audio features alone: ~80-89% accuracy (Rusconi 2024, arxiv:2508.11632)
  # - Adding artist popularity: +15% (Interiano 2018)
  # - Adding engagement metrics: +10-60% (multi-signal studies)
  # - Release recency correlates with popularity (SpotiPred 2022)
  SIGNAL_WEIGHTS = {
    audio_features: 0.50,
    artist_popularity: 0.20,
    engagement: 0.15,
    release_recency: 0.15
  }.freeze

  # Audio feature weights based on Random Forest feature importance from Rusconi (2024).
  # Popular songs tend to be loud, danceable, energetic, non-acoustic, with moderate valence and tempo.
  AUDIO_FEATURE_WEIGHTS = {
    loudness: 0.20,
    danceability: 0.18,
    energy: 0.16,
    acousticness: 0.14,
    valence: 0.10,
    tempo: 0.10,
    instrumentalness: 0.05,
    speechiness: 0.04,
    liveness: 0.03
  }.freeze

  # Optimal ranges for popular songs derived from the research dataset.
  # Each feature maps to a center and spread for a Gaussian-like scoring function.
  OPTIMAL_RANGES = {
    danceability: { center: 0.64, spread: 0.20 },
    energy: { center: 0.68, spread: 0.22 },
    valence: { center: 0.52, spread: 0.25 },
    acousticness: { center: 0.15, spread: 0.20 },
    instrumentalness: { center: 0.02, spread: 0.10 },
    speechiness: { center: 0.08, spread: 0.15 },
    liveness: { center: 0.17, spread: 0.15 },
    tempo: { center: 120.0, spread: 30.0 },
    loudness: { center: -6.0, spread: 4.0 }
  }.freeze

  # Max values for log-normalization of engagement metrics
  MAX_LASTFM_LISTENERS = 8.0  # log10(100M)
  MAX_LASTFM_PLAYCOUNT = 9.0  # log10(1B)
  MAX_SPOTIFY_FOLLOWERS = 8.0 # log10(100M)

  def initialize(song)
    @song = song
    @music_profile = song.music_profile
  end

  def calculate
    return nil if @music_profile.blank?

    score = audio_features_score * SIGNAL_WEIGHTS[:audio_features] +
            artist_popularity_score * SIGNAL_WEIGHTS[:artist_popularity] +
            engagement_score * SIGNAL_WEIGHTS[:engagement] +
            release_recency_score * SIGNAL_WEIGHTS[:release_recency]

    (score * 100).round(2).clamp(0.0, 100.0)
  end

  private

  def audio_features_score
    AUDIO_FEATURE_WEIGHTS.sum do |feature, weight|
      value = @music_profile.public_send(feature)
      next 0.0 if value.nil?

      gaussian_score(feature, value.to_f) * weight
    end
  end

  def gaussian_score(feature, value)
    optimal = OPTIMAL_RANGES[feature]
    distance = (value - optimal[:center]) / optimal[:spread]
    Math.exp(-0.5 * distance**2)
  end

  # Artist popularity signal (Interiano 2018: artist fame jumped accuracy 70% → 85%)
  # Uses the primary artist's Spotify popularity, followers, and Last.fm data.
  def artist_popularity_score
    artist = @song.artists.first
    return 0.0 if artist.blank?

    spotify_pop = (artist.spotify_popularity || 0) / 100.0
    followers = log_normalize(artist.spotify_followers_count, MAX_SPOTIFY_FOLLOWERS)
    listeners = log_normalize(artist.lastfm_listeners, MAX_LASTFM_LISTENERS)

    spotify_pop * 0.50 + followers * 0.25 + listeners * 0.25
  end

  # Engagement metrics from song-level data (Mountzouris 2025: Spotify popularity was
  # the most decisive single predictor; multi-signal studies show 10-60% improvement).
  def engagement_score
    spotify_pop = (@song.popularity || 0) / 100.0
    listeners = log_normalize(@song.lastfm_listeners, MAX_LASTFM_LISTENERS)
    playcount = log_normalize(@song.lastfm_playcount, MAX_LASTFM_PLAYCOUNT)

    spotify_pop * 0.50 + listeners * 0.30 + playcount * 0.20
  end

  # Release recency signal (SpotiPred 2022: recent releases correlate with popularity).
  # Songs released within the last year score highest, decaying over 5 years.
  def release_recency_score
    return 0.5 if @song.release_date.blank?

    days_old = (Date.current - @song.release_date).to_i
    return 1.0 if days_old <= 0

    decay_years = 5.0
    Math.exp(-days_old / (decay_years * 365.0))
  end

  def log_normalize(value, max_exponent)
    return 0.0 if value.nil? || value <= 0

    Math.log10(value).clamp(0.0, max_exponent) / max_exponent
  end
end
