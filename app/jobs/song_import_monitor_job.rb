# frozen_string_literal: true

class SongImportMonitorJob
  include Sidekiq::Worker
  sidekiq_options queue: 'low'

  def perform
    monitor = SongImportMonitor.new(time_window: 1.hour)

    # Check overall failure rate
    stats = monitor.check_failure_rate
    log_stats(stats) if stats

    # Check per-station failure rates
    monitor.check_failure_rate_by_station
  end

  private

  def log_stats(stats)
    return unless stats[:failure_rate] > 0.1 # Only log if failure rate exceeds 10%

    Rails.logger.warn(
      'SongImportMonitorJob: High failure rate - ' \
      "Total: #{stats[:total]}, " \
      "Success: #{stats[:success]}, " \
      "Failed: #{stats[:failed]}, " \
      "Skipped: #{stats[:skipped]}, " \
      "Failure rate: #{(stats[:failure_rate] * 100).round(1)}%"
    )
  end
end
