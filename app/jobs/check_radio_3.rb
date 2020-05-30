# frozen_string_literal: true

class CheckRadio3 < ApplicationJob 
  queue_as :default

  def perform
    Generalplaylist.radio_3fm_check
  end
end
