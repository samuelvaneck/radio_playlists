# frozen_string_literal: true

class ChartsController < ApplicationController
  def show
    historic_start_time = params[:start_time].present? ? Time.zone.strptime(params[:start_time], '%Y-%m-%dT%R') : 1.week.ago
    historic_chart = Chart.find_by(date: historic_start_time.beginning_of_day, chart_type: params[:chart_type])
    historic_position = historic_chart ? historic_chart.position(params[:id]) : []

    render json: { historic_position: }
  end
end
