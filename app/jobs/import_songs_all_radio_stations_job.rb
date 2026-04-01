# frozen_string_literal: true

class ImportSongsAllRadioStationsJob < ApplicationJob
  queue_as :default

  def perform
    RadioStation.unscoped.recognizer_only.find_each do |radio_station|
      ImportSongJob.set(queue: 'recognition').perform_async(radio_station.id)
      sleep 2
    end

    RadioStation.unscoped.with_api_processor.find_each do |radio_station|
      if radio_station.import_interval.present?
        enqueue_bulk_import(radio_station)
      else
        ImportSongJob.set(queue: 'api_scraping').perform_async(radio_station.id)
      end
    end
  end

  private

  def enqueue_bulk_import(radio_station)
    last_import = radio_station.song_import_logs.order(created_at: :desc).pick(:created_at)
    return if last_import && last_import > radio_station.import_interval.minutes.ago

    BulkImportSongsJob.set(queue: 'api_scraping').perform_async(radio_station.id)
  end
end
