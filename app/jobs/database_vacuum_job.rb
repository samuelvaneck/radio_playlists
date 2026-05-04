# frozen_string_literal: true

class DatabaseVacuumJob
  TABLES = %w[air_plays chart_positions songs song_import_logs radio_station_songs artists artists_songs].freeze

  include Sidekiq::Worker
  sidekiq_options queue: 'compute'

  def perform
    TABLES.each do |table|
      vacuum_table(table)
    rescue StandardError => e
      Rails.logger.error("DatabaseVacuumJob: VACUUM ANALYZE #{table} failed: #{e.message}")
    end
  end

  private

  def vacuum_table(table)
    ActiveRecord::Base.connection.raw_connection.exec("VACUUM ANALYZE #{table}")
    Rails.logger.info("DatabaseVacuumJob: VACUUM ANALYZE #{table} completed")
  end
end
