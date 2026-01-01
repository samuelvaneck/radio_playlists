# frozen_string_literal: true

class SongImportLogCleanupJob
  CSV_EXPORT_DIR = Rails.root.join('tmp/song_import_logs')
  CSV_RETENTION_DAYS = 7

  include Sidekiq::Worker
  sidekiq_options queue: 'low'

  def perform
    cleanup_database_logs
    cleanup_old_csv_files
  end

  private

  def cleanup_database_logs
    logs_to_export = SongImportLog.older_than(1.day.ago)

    if logs_to_export.exists?
      export_to_csv(logs_to_export)
      deleted_count = logs_to_export.delete_all
      Rails.logger.info("SongImportLogCleanupJob: Exported and deleted #{deleted_count} song import logs")
    else
      Rails.logger.info('SongImportLogCleanupJob: No database logs to cleanup')
    end
  end

  def cleanup_old_csv_files
    return unless CSV_EXPORT_DIR.exist?

    deleted_count = 0
    Dir.glob(CSV_EXPORT_DIR.join('*.csv')).each do |file|
      if File.mtime(file) < CSV_RETENTION_DAYS.days.ago
        File.delete(file)
        deleted_count += 1
      end
    end

    Rails.logger.info("SongImportLogCleanupJob: Deleted #{deleted_count} old CSV files") if deleted_count.positive?
  end

  def export_to_csv(logs)
    ensure_export_directory_exists
    csv_content = SongImportLog.to_csv(logs)
    File.write(csv_file_path, csv_content)
    File.chmod(0o600, csv_file_path) # Owner read/write only
    Rails.logger.info("SongImportLogCleanupJob: Exported logs to #{csv_file_path}")
  end

  def ensure_export_directory_exists
    FileUtils.mkdir_p(CSV_EXPORT_DIR)
  end

  def csv_file_path
    timestamp = Time.zone.now.strftime('%Y-%m-%d_%H%M%S')
    CSV_EXPORT_DIR.join("song_import_logs_#{timestamp}.csv")
  end
end
