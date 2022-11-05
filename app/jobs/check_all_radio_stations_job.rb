# frozen_string_literal: true

class CheckAllRadioStationsJob < ApplicationJob
  queue_as :default

  def perform
    RadioStation.all.each do |radio_station|
      ImportSongJob.perform_async(radio_station.id)
      sleep 5
    end
  end
end
