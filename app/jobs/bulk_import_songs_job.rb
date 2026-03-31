# frozen_string_literal: true

class BulkImportSongsJob
  include Sidekiq::Worker

  sidekiq_options lock: :until_executed, lock_ttl: 300

  def perform(id)
    radio_station = RadioStation.find(id)
    processor = "TrackScraper::#{radio_station.processor.camelcase}".constantize.new(radio_station)
    played_songs = processor.all_played_songs
    return if played_songs.blank?

    played_songs.each do |played_song|
      next if air_play_exists?(radio_station, played_song.broadcasted_at)

      SongImporter.new(radio_station: radio_station, played_song: played_song).import
    end
  rescue StandardError => e
    Rails.logger.error "BulkImportSongsJob error for #{radio_station&.name}: #{e.message}"
    ExceptionNotifier.notify(e, 'BulkImportSongsJob')
  end

  private

  def air_play_exists?(radio_station, broadcasted_at)
    radio_station.air_plays.exists?(broadcasted_at: broadcasted_at)
  end
end
