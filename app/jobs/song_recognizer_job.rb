class SongRecognizerJob < ApplicationJob
  queue_as :default

  def perform
    RadioStation.all.each do |radio_station|
      radio_station.enqueue_recognize_song
    end
  end
end
