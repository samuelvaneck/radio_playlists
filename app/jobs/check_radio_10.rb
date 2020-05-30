# frozen_string_literal: true

class CheckRadio10 < ApplicationJob 
  queue_as :default

  def perform
    Generalplaylist.radio_10_check
  end
end
