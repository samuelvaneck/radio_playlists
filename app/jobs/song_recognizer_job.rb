class SongRecognizerJob < ApplicationJob
  queue_as :default

  def perform
    RadioStation.all.find_each(&:enqueue_recognize_song)
  end
end
