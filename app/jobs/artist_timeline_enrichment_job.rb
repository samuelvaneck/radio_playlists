# frozen_string_literal: true

class ArtistTimelineEnrichmentJob
  THROTTLE_INTERVAL = 3
  RECHECK_AFTER = 30.days

  include Sidekiq::Job
  sidekiq_options queue: 'enrichment', lock: :until_executed, lock_ttl: 1.hour

  def self.enqueue_all
    scope = Artist.where.not(id_on_musicbrainz: nil)
    scope.find_each.with_index do |artist, index|
      perform_in((index * THROTTLE_INTERVAL).seconds, artist.id)
    end
  end

  def self.enqueue_stale(after: RECHECK_AFTER)
    threshold = after.ago
    artist_ids = Artist.where.not(id_on_musicbrainz: nil)
                   .left_outer_joins(:timeline)
                   .where('artist_timelines.fetched_at IS NULL OR artist_timelines.fetched_at < ?', threshold)
                   .pluck(:id)

    artist_ids.each_with_index do |artist_id, index|
      perform_in((index * THROTTLE_INTERVAL).seconds, artist_id)
    end
  end

  def perform(artist_id)
    artist = Artist.find_by(id: artist_id)
    return if artist.blank? || artist.id_on_musicbrainz.blank?

    payload = ArtistTimelineBuilder.new(artist).()
    upsert_timeline(artist, payload)
  end

  private

  def upsert_timeline(artist, payload)
    timeline = artist.timeline || artist.build_timeline
    timeline.assign_attributes(
      events: payload['events'],
      musicbrainz_id: payload['musicbrainz_id'],
      wikidata_id: payload['wikidata_id'],
      llm_enriched: llm_enriched?(payload['events']),
      fetched_at: Time.current
    )
    timeline.save!
  end

  def llm_enriched?(events)
    events.any? { |event| event.key?('summary') || event.key?('notable') }
  end
end
