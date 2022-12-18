# frozen_string_literal: true

class RadioStationRecognizeSongJob < ApplicationJob
  queue_as :default

  def perform(radio_station_id)
    RadioStation.find(radio_station_id).recognize_song
  end
end
