class UpdateItemChartPositionsJob
  include Sidekiq::Worker

  sidekiq_options queue: 'low', lock: :until_executed

  def perform(args)
    @args = args
    return if item.nil?

    chart_positions = current_chart_positions
    # Incremental update of chart positions to avoid updating all chart positions
    # When no chart positions are present, create a new one
    new_chart_positions = if chart_positions.blank?
                            [parsed_chart_positions]
                          # When the last chart position date is the day before the current date, add the new chart position
                          elsif (last_chart_position_date + 1.day) == Date.parse(@args['chart_date'])
                            chart_positions << parsed_chart_positions
                            chart_positions
                          # when the last chart position date is not the day before the current date, fill in the missing days
                          else
                            (last_chart_position_date + 1.day).upto(Date.parse(@args['chart_date']) - 1.day) do |date|
                              chart_positions << { date: date.to_s, position: 0, counts: 0 }
                            end
                            chart_positions << parsed_chart_positions
                            chart_positions
                          end

    item.update(cached_chart_positions: new_chart_positions, cached_chart_positions_updated_at: Time.zone.now)
  end

  private

  def item
    @item ||= @args['item_type'].singularize.classify.constantize.find(@args['item_id'])
  end

  def current_chart_positions
    item.cached_chart_positions
  end

  def last_chart_position_date
    Date.parse(current_chart_positions.last['date'])
  end

  def parsed_chart_positions
    { date: @args['chart_date'], position: @args['chart_position'], counts: @args['chart_counts'] }
  end
end
