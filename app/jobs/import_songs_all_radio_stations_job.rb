# frozen_string_literal: true

class ImportSongsAllRadioStationsJob < ApplicationJob
  queue_as :default

  def perform
    RadioStation.all.each do |radio_station|
      ImportSongJob.perform_async(radio_station.id)
      sleep 2
    end
  end
end
