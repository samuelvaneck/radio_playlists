# frozen_string_literal: true

class CheckGrootNieuwsRadio < ApplicationJob
  queue_as :default

  def perform
    Generalplaylist.grootnieuws_radio_check
  end
end
