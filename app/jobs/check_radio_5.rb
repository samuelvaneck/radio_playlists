# frozen_string_literal: true

class CheckRadio5 < ApplicationJob 
  queue_as :default

  def perform
    Generalplaylist.radio_5_check
  end
end
