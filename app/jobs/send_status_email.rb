# frozen_string_literal: true

class SendStatusEmail < ApplicationJob
  queue_as :default

  def perform
    results = {}
    RadioStation.all.find_each do |radio_station|
      next if radio_station.blank?

      results[radio_station.status] ||= []
      results[radio_station.status] << { "#{radio_station.name}": radio_station.status_data }
    end

    StatusMailer.status_mail('samuelvaneck@gmail.com', results).deliver
  end
end
