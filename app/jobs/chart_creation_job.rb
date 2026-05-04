# frozen_string_literal: true

class ChartCreationJob
  include Sidekiq::Worker
  sidekiq_options queue: 'compute'

  def perform
    Chart.create_yesterday_charts
  end
end
