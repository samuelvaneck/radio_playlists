# frozen_string_literal: true

class ChartCreationJob < ApplicationJob
  queue_as :default

  def perform
    Chart.create_yesterdays_charts
  end
end
