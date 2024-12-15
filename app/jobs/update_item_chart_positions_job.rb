class UpdateItemChartPositionsJob < ApplicationJob
  queue_as :default

  def perform(item_id, item_type)
    item_type.singularize.classify.constantize.find(item_id)&.update_chart_positions
  end
end
