# frozen_string_literal: true

class LyricsEnrichmentBatchJob
  include Sidekiq::Job
  sidekiq_options queue: 'enrichment'

  def perform
    LyricsEnrichmentJob.enqueue_all
  end
end
