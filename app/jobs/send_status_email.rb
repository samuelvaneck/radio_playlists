# frozen_string_literal: true

class SendStatusEmail < ApplicationJob
  queue_as :default

  def perform
    results = {}
    Radiostation.all.each do |radio_station|
      next if radio_station.status[:last_created_at] > 3.hours.ago

      results[radio_station.name.to_s] = radio_station.status
    end

    StatusMailer.status_mail('samuelvaneck@gmail.com', results).deliver
  end
end
