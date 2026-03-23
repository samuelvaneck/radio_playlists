# frozen_string_literal: true

class ImportSongJob
  include Sidekiq::Worker

  sidekiq_options lock: :until_executed, lock_ttl: 60

  def perform(id)
    radio_station = RadioStation.find(id)
    SongImporter.new(radio_station: radio_station).import
  rescue StandardError => e
    Rails.logger.error "ImportSongJob error for #{radio_station&.name}: #{e.message}"
    ExceptionNotifier.notify(e, 'ImportSongJob')
  end
end
