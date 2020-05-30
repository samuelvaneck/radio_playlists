# frozen_string_literal: true

class CheckRadio2 < ApplicationJob 
  queue_as :default

  def perform
    Generalplaylist.radio_2_check
  end
end
