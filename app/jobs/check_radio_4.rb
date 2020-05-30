# frozen_string_literal: true

class CheckRadio4 < ApplicationJob 
  queue_as :default

  def perform
    Generalplaylist.radio_4_check
  end
end
