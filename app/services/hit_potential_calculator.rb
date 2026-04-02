# frozen_string_literal: true

class HitPotentialCalculator
  # Feature weights based on Random Forest feature importance from Rusconi (2024).
  # Research: https://arno.uvt.nl/show.cgi?fid=171864
  # Popular songs tend to be loud, danceable, energetic, non-acoustic, with moderate valence and tempo.
  FEATURE_WEIGHTS = {
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

  def initialize(music_profile)
    @music_profile = music_profile
  end

  def calculate
    return nil if @music_profile.blank?

    score = FEATURE_WEIGHTS.sum do |feature, weight|
      value = @music_profile.public_send(feature)
      next 0.0 if value.nil?

      feature_score(feature, value.to_f) * weight
    end

    (score * 100).round(2).clamp(0.0, 100.0)
  end

  private

  def feature_score(feature, value)
    optimal = OPTIMAL_RANGES[feature]
    distance = (value - optimal[:center]) / optimal[:spread]
    Math.exp(-0.5 * distance**2)
  end
end
