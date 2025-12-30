# frozen_string_literal: true

class Broadcaster
  attr_reader :message, :color

  def self.last_song(title:, artists_names:, radio_station_name:)
    new(message: "*** #{title} from #{artists_names} last song on #{radio_station_name} ***", color: 'blue').broadcast
  end

  def self.no_importing_song
    new(message: 'No importing song', color: 'red').broadcast
  end

  def self.no_importing_artists
    new(message: 'No importing artists', color: 'red').broadcast
  end

  def self.illegal_word_in_title(title:)
    new(message: "Found illegal word in #{title}", color: 'red').broadcast
  end

  def self.song_draft_created(title:, song_id:, artists_names:, radio_station_name:)
    new(message: "Draft: #{title} (#{song_id}) from #{artists_names} on #{radio_station_name}", color: 'blue').broadcast
  end

  def self.song_confirmed(title:, song_id:, artists_names:, radio_station_name:)
    new(message: "*** Confirmed #{title} (#{song_id}) from #{artists_names} on #{radio_station_name}! ***", color: 'green').broadcast
  end

  def self.no_artists_or_song(title:, radio_station_name:)
    new(message: "No artists or song found for #{title} on #{radio_station_name}", color: 'red').broadcast
  end

  def self.error_during_import(error_message:, radio_station_name:)
    new(message: "Error while importing song from #{radio_station_name}: #{error_message}", color: 'red').broadcast
  end

  def self.song_added(title:, song_id:, artists_names:, artist_ids:, radio_station_name:)
    new(message: "*** Saved #{title} (#{song_id}) from #{artists_names} (#{artist_ids}) on #{radio_station_name}! ***", color: 'green').broadcast
  end

  def initialize(message:, color: nil)
    @message = message
    @color = color
  end

  def broadcast
    Rails.logger.info(color.present? ? colorized_message : message)
    nil
  end

  def colorized_message
    ActiveSupport::LogSubscriber.new.send(:color, message, color&.to_sym)
  end
end
