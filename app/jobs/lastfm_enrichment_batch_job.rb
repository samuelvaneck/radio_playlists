# frozen_string_literal: true

class LastfmEnrichmentBatchJob
  include Sidekiq::Job
  sidekiq_options queue: 'low'

  def perform
    LastfmEnrichmentJob.enqueue_all
  end
end
