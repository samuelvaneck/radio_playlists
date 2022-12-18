class SongRecognizerJob < ApplicationJob
  queue_as :default

  def perform(*args)
    RadioStation.all.each do |radio_station|
      radio_station.recognize_song
    end
  end
end
