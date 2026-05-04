# frozen_string_literal: true

class ArtistEnrichmentJob
  # Wikipedia allows 500 requests/hour without a token.
  # Each job makes ~2 Wikipedia API calls (summary + full content),
  # so max 250 jobs/hour → 3600 / 250 ≈ 15 seconds between jobs.
  WIKIPEDIA_RATE_LIMIT_PER_HOUR = 500
  WIKIPEDIA_REQUESTS_PER_JOB = 2
  THROTTLE_INTERVAL = (3600.0 / (WIKIPEDIA_RATE_LIMIT_PER_HOUR / WIKIPEDIA_REQUESTS_PER_JOB)).ceil
  RECHECK_AFTER = 90.days

  include Sidekiq::Job
  sidekiq_options queue: 'enrichment'

  def self.enqueue_all
    stale_threshold = RECHECK_AFTER.ago
    scope = Artist
              .where(country_of_origin: [])
              .where('country_of_origin_checked_at IS NULL OR country_of_origin_checked_at < ?', stale_threshold)

    scope.find_each.with_index do |artist, index|
      perform_in((index * THROTTLE_INTERVAL).seconds, artist.id)
    end
  end

  def perform(artist_id)
    artist = Artist.find_by(id: artist_id)
    return if artist.blank?
    return if artist.country_of_origin.present?
    return if artist.country_of_origin_checked_at.present? && artist.country_of_origin_checked_at > RECHECK_AFTER.ago

    enrich_country_of_origin(artist)
    enrich_spotify_metrics(artist)
    artist.update(country_of_origin_checked_at: Time.current)
  end

  private

  def enrich_country_of_origin(artist)
    return if artist.country_of_origin.present?

    info = Wikipedia::ArtistFinder.new.get_info(artist.name)
    return if info.blank?

    nationality = info.dig('general_info', 'nationality')
    artist.update(country_of_origin: nationality) if nationality.present?
  end

  def enrich_spotify_metrics(artist)
    return if artist.id_on_spotify.blank?

    spotify_artist = Spotify::ArtistFinder.new(id_on_spotify: artist.id_on_spotify).info
    return if spotify_artist.blank?

    updates = {}
    updates[:spotify_popularity] = spotify_artist['popularity'] if spotify_artist['popularity'].present?
    updates[:spotify_followers_count] = spotify_artist.dig('followers', 'total') if spotify_artist.dig('followers', 'total').present?
    artist.update(updates) if updates.present?
  end
end
