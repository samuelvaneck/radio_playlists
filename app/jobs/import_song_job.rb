# frozen_string_literal: true

class ImportSongJob
  IMPORT_TIMEOUT_SECONDS = 60

  include Sidekiq::Worker

  # lock_ttl must outlive IMPORT_TIMEOUT_SECONDS so the unique-jobs lock spans
  # the full execution. If the job ran longer than lock_ttl, the lock would
  # auto-expire and the per-minute scheduler would enqueue a duplicate while
  # the original is still running, causing pile-up across all worker threads.
  sidekiq_options lock: :until_executed, lock_ttl: 90

  def perform(id)
    radio_station = RadioStation.find(id)
    Timeout.timeout(IMPORT_TIMEOUT_SECONDS) do
      SongImporter.new(radio_station: radio_station).import
    end
  rescue Timeout::Error => e
    Rails.logger.warn "ImportSongJob timed out after #{IMPORT_TIMEOUT_SECONDS}s for #{radio_station&.name}"
    ExceptionNotifier.notify(e, 'ImportSongJob timeout')
  rescue StandardError => e
    Rails.logger.error "ImportSongJob error for #{radio_station&.name}: #{e.message}"
    ExceptionNotifier.notify(e, 'ImportSongJob')
  end
end
