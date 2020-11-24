# frozen_string_literal: true

class CheckAllRadioStationsJob < ApplicationJob
  queue_as :default

  def perform
    Radiostation.all.each do |radio_station|
      radio_station.import_song
      sleep 10
    end
  end
end
