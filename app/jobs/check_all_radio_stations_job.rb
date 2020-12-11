# frozen_string_literal: true

class CheckAllRadioStationsJob < ApplicationJob
  queue_as :default

  def perform
    Radiostation.all.each do |radio_station|
      puts "****** Import song #{radio_station.name} ******"
      radio_station.import_song
      sleep 10
    rescue StandardError => e
      puts "****** Error #{e} ******"
      next
    end
  end
end
