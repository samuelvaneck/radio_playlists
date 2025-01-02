# frozen_string_literal: true

class ImportSongJob
  include Sidekiq::Worker

  sidekiq_options lock: :until_executed

  def perform(id)
    radio_station = RadioStation.find(id)
    Rails.logger.info "****** Import song #{radio_station.name} ******"
    SongImporter.new(radio_station: radio_station).import
  rescue StandardError => e
    Rails.logger.info "****** Error #{e} ******"
  end
end
