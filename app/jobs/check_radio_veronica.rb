# frozen_string_literal: true

class CheckRadioVeronica < ApplicationJob 
  queue_as :default

  def perform
    Generalplaylist.radio_veronica_check
  end
end
