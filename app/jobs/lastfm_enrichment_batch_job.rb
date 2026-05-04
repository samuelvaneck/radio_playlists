# frozen_string_literal: true

class LastfmEnrichmentBatchJob
  include Sidekiq::Job
  sidekiq_options queue: 'enrichment'

  def perform
    LastfmEnrichmentJob.enqueue_all
  end
end
