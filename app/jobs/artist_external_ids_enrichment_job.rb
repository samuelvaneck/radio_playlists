# frozen_string_literal: true

class ArtistExternalIdsEnrichmentJob
  include Sidekiq::Job

  sidekiq_options queue: :enrichment, retry: 3

  def self.enqueue_all
    scope = Artist
              .where(id_on_tidal: nil)
              .or(Artist.where(id_on_deezer: nil))
              .or(Artist.where(id_on_itunes: nil))

    scope.find_each { |artist| perform_async(artist.id) }
  end

  def perform(artist_id)
    artist = Artist.find_by(id: artist_id)
    return if artist.blank?
    return unless artist.needs_external_ids_enrichment?

    artist.enrich_with_external_services
  end
end
