# frozen_string_literal: true

class ImportSongJob
  include Sidekiq::Worker

  sidekiq_options lock: :until_executed

  def perform(id)
    radio_station = RadioStation.find(id)
    SongImporter.new(radio_station: radio_station).import
  rescue StandardError => e
    Rails.logger.error "ImportSongJob error for #{radio_station&.name}: #{e.message}"
    ExceptionNotifier.notify_new_relic(e, 'ImportSongJob')
  end
end
