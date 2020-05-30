# frozen_string_literal: true

class CheckSkyRadio < ApplicationJob 
  queue_as :default

  def perform
    Generalplaylist.sky_radio_check
  end
end
