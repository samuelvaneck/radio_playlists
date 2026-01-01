# frozen_string_literal: true

class CleanupDraftAirPlaysJob
  include Sidekiq::Worker
  sidekiq_options queue: 'low'

  def perform
    draft_air_play_ids = AirPlay.draft.where('created_at < ?', 4.hours.ago).pluck(:id)
    return if draft_air_play_ids.empty?

    SongImportLog.where(air_play_id: draft_air_play_ids).update_all(air_play_id: nil) # rubocop:disable Rails/SkipsModelValidations
    deleted_count = AirPlay.where(id: draft_air_play_ids).delete_all
    Rails.logger.info("CleanupDraftAirPlaysJob: Deleted #{deleted_count} draft air_plays")
  end
end
