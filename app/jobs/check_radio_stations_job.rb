# frozen_string_literal: true

class CheckRadioStationsJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: false

  def perform
    Generalplaylist.check_all_radiostations
  end
end
