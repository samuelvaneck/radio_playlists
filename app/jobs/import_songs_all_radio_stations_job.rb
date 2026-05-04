# frozen_string_literal: true

class ImportSongsAllRadioStationsJob < ApplicationJob
  queue_as :realtime

  def perform
    RadioStation.unscoped.recognizer_only.find_each do |radio_station|
      ImportSongJob.perform_async(radio_station.id)
      sleep 2
    end

    RadioStation.unscoped.with_api_processor.find_each do |radio_station|
      ImportSongJob.perform_async(radio_station.id)
    end
  end
end
