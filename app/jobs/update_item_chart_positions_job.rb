class UpdateItemChartPositionsJob
  include Sidekiq::Worker
  sidekiq_options queue: 'low'

  def perform(item_id, item_type)
    item_type.singularize.classify.constantize.find(item_id)&.update_chart_positions
  end
end
