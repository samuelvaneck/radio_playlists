# frozen_string_literal: true

class CleanupDraftAirPlaysJob
  include Sidekiq::Worker
  sidekiq_options queue: 'low'

  def perform
    deleted_count = AirPlay.draft.where('created_at < ?', 4.hours.ago).delete_all
    Rails.logger.info("CleanupDraftAirPlaysJob: Deleted #{deleted_count} draft air_plays")
  end
end
