# frozen_string_literal: true

class CheckRadio538 < ApplicationJob 
  queue_as :default

  def perform
    Generalplaylist.radio_538_check
  end
end
