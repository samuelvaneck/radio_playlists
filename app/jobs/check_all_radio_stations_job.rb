# frozen_string_literal: true

class CheckAllRadioStationsJob < ApplicationJob
  queue_as :default

  def perform
    Radiostation.all.each do |radio_station|
      ImportSongJob.perform_async(radio_station.id)
      sleep 10
    end
  end
end
