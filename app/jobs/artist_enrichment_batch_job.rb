# frozen_string_literal: true

class ArtistEnrichmentBatchJob
  include Sidekiq::Job
  sidekiq_options queue: 'low'

  def perform
    ArtistEnrichmentJob.enqueue_all
  end
end
