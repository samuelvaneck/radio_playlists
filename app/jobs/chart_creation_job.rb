# frozen_string_literal: true

class ChartCreationJob < ApplicationJob
  queue_as :default

  def perform
    Chart.create_yesterday_charts
  end
end
