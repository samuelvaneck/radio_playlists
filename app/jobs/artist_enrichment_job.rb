# frozen_string_literal: true

class ArtistEnrichmentJob
  THROTTLE_INTERVAL = 2 # seconds between jobs

  include Sidekiq::Job
  sidekiq_options queue: 'low'

  def self.enqueue_all
    Artist.where(country_of_origin: []).find_each.with_index do |artist, index|
      perform_in((index * THROTTLE_INTERVAL).seconds, artist.id)
    end
  end

  def perform(artist_id)
    artist = Artist.find_by(id: artist_id)
    return if artist.blank?

    enrich_country_of_origin(artist)
    enrich_spotify_metrics(artist)
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
