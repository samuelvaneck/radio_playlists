# frozen_string_literal: true

class ImportSongJob
  include Sidekiq::Worker

  def perform(id)
    radio_station = RadioStation.find(id)
    Rails.logger.info "****** Import song #{radio_station.name} ******"
    radio_station.import_song
  rescue StandardError => e
    Rails.logger.info "****** Error #{e} ******"
  end
end
