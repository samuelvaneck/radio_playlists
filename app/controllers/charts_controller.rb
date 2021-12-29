# frozen_string_literal: true

class ChartsController < ApplicationController
  def show
    one_week_ago = 1.week.ago.beginning_of_day
    last_week_chart = Chart.find_by(date: one_week_ago, chart_type: params[:chart_type])
    last_week_position = last_week_chart.position(params[:object_id])

    yesterday = Time.zone.strptime(params[:start_time], '%Y-%m-%dT%R')
    yesterday_chart = Chart.find_by(date: yesterday, chart_type: params[:chart_type])
    yesterdays_position = yesterday_chart.position(params[:object_id])

    render json: [last_week_position, yesterdays_position]
  end
end
