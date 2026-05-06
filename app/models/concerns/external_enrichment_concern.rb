# frozen_string_literal: true

module ExternalEnrichmentConcern
  extend ActiveSupport::Concern

  def enrich_with_external_services
    enrich_with_deezer if should_enrich_with_deezer?
    enrich_with_itunes if should_enrich_with_itunes?
    enrich_with_tidal if should_enrich_with_tidal?
    enrich_with_music_brainz if should_enrich_with_music_brainz?
  end

  def needs_external_ids_enrichment?
    should_enrich_with_deezer? || should_enrich_with_itunes? ||
      should_enrich_with_tidal? || should_enrich_with_music_brainz?
  end

  private

  def should_enrich_with_deezer?
    (id_on_deezer.blank? || duration_ms.blank?) && (isrcs.present? || title.present?)
  end

  def should_enrich_with_itunes?
    (id_on_itunes.blank? || duration_ms.blank?) && title.present?
  end

  def should_enrich_with_tidal?
    id_on_tidal.blank? && title.present?
  end

  def should_enrich_with_music_brainz?
    isrcs.size == 1
  end
end
