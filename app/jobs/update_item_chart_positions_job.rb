class UpdateItemChartPositionsJob
  include Sidekiq::Worker

  sidekiq_options queue: 'low', lock: :until_executed

  def perform(args)
    args['item_type'].singularize.classify.constantize.find(args['item_id'])&.update_chart_positions
  end
end
