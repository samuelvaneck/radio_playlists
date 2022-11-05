# frozen_string_literal: true

class ImportSongJob
  include Sidekiq::Worker

  def perform(id)
    radio_station = RadioStation.find(id)
    puts "****** Import song #{radio_station.name} ******"
    radio_station.import_song
  rescue StandardError => e
    puts "****** Error #{e} ******"
  end
end
