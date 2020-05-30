# frozen_string_literal: true

class CheckRadio1 < ApplicationJob 
  queue_as :default

  def perform
    Generalplaylist.radio_1_check
  end
end
