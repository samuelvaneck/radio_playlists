# frozen_string_literal: true

class ArtistTimelineEnrichmentBatchJob
  include Sidekiq::Job
  sidekiq_options queue: 'enrichment'

  def perform
    ArtistTimelineEnrichmentJob.enqueue_stale
  end
end
