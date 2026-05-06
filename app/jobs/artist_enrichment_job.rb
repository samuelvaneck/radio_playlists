# frozen_string_literal: true

class ArtistEnrichmentJob
  # MusicBrainz asks clients to keep below 1 req/sec; the country finder
  # makes up to 2 sequential calls per artist (search + lookup), each with
  # a 1-second sleep, so a 3-second spacing between jobs leaves headroom.
  THROTTLE_INTERVAL = 3
  RECHECK_AFTER = 90.days

  include Sidekiq::Job
  sidekiq_options queue: 'enrichment'

  def self.enqueue_all
    stale_threshold = RECHECK_AFTER.ago
    scope = Artist
              .where(country_code: nil)
              .where('country_of_origin_checked_at IS NULL OR country_of_origin_checked_at < ?', stale_threshold)

    scope.find_each.with_index do |artist, index|
      perform_in((index * THROTTLE_INTERVAL).seconds, artist.id)
    end
  end

  def perform(artist_id)
    artist = Artist.find_by(id: artist_id)
    return if artist.blank?
    return if artist.country_code.present?
    return if artist.country_of_origin_checked_at.present? && artist.country_of_origin_checked_at > RECHECK_AFTER.ago

    enrich_country_of_origin(artist)
    enrich_spotify_metrics(artist)
    artist.update(country_of_origin_checked_at: Time.current)
  end

  private

  def enrich_country_of_origin(artist)
    return if artist.country_code.present?

    iso_code = MusicBrainz::ArtistCountryFinder.new(artist).()
    return if iso_code.blank?

    country = ISO3166::Country.new(iso_code)
    return if country.nil?

    artist.update(country_code: iso_code, country_of_origin: [country.common_name || country.iso_short_name])
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
