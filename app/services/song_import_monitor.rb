# frozen_string_literal: true

class SongImportMonitor
  FAILURE_RATE_THRESHOLD = 0.3 # 30% failure rate triggers alert
  MINIMUM_SAMPLE_SIZE = 10 # Need at least 10 imports to calculate meaningful rate

  def initialize(time_window: 1.hour)
    @time_window = time_window
  end

  def check_failure_rate
    stats = calculate_stats
    return nil unless stats[:total] >= MINIMUM_SAMPLE_SIZE

    log_high_failure_rate(stats) if stats[:failure_rate] > FAILURE_RATE_THRESHOLD

    stats
  end

  def check_failure_rate_by_station
    RadioStation.find_each do |station|
      stats = calculate_stats_for_station(station)
      next unless stats[:total] >= MINIMUM_SAMPLE_SIZE

      log_high_failure_rate_for_station(station, stats) if stats[:failure_rate] > FAILURE_RATE_THRESHOLD
    end
  end

  private

  def calculate_stats
    logs = recent_logs
    total = logs.count
    return { total: 0, success: 0, failed: 0, skipped: 0, failure_rate: 0.0 } if total.zero?

    failed = logs.failed.count
    {
      total:,
      success: logs.success.count,
      failed:,
      skipped: logs.skipped.count,
      pending: logs.pending.count,
      failure_rate: failed.to_f / total
    }
  end

  def calculate_stats_for_station(station)
    logs = recent_logs.where(radio_station: station)
    total = logs.count
    return { total: 0, success: 0, failed: 0, skipped: 0, failure_rate: 0.0 } if total.zero?

    failed = logs.failed.count
    {
      total:,
      success: logs.success.count,
      failed:,
      skipped: logs.skipped.count,
      pending: logs.pending.count,
      failure_rate: failed.to_f / total
    }
  end

  def recent_logs
    SongImportLog.where(created_at: @time_window.ago..)
  end

  def log_high_failure_rate(stats)
    Rails.logger.warn(
      'SongImportMonitor: High failure rate detected! ' \
      "Rate: #{format_percentage(stats[:failure_rate])} " \
      "(#{stats[:failed]}/#{stats[:total]} imports failed in last #{format_time_window})"
    )
  end

  def log_high_failure_rate_for_station(station, stats)
    Rails.logger.warn(
      "SongImportMonitor: High failure rate for #{station.name}! " \
      "Rate: #{format_percentage(stats[:failure_rate])} " \
      "(#{stats[:failed]}/#{stats[:total]} imports failed in last #{format_time_window})"
    )
  end

  def format_percentage(rate)
    "#{(rate * 100).round(1)}%"
  end

  def format_time_window
    hours = (@time_window / 1.hour).to_i
    hours == 1 ? 'hour' : "#{hours} hours"
  end
end
