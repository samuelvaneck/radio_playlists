# frozen_string_literal: true

module Api
  module V1
    class ChartsController < ApiController
      def index
        render json: ChartPositionSerializer.new(chart_positions, params: { previous_positions: previous_positions })
                       .serializable_hash
                       .merge(chart_metadata)
                       .merge(pagination_data(chart_positions))
                       .to_json
      end

      def search
        render json: ChartPositionSerializer.new(searched_chart_positions, params: { previous_positions: previous_positions })
                       .serializable_hash
                       .merge(chart_metadata)
                       .merge(pagination_data(searched_chart_positions))
                       .to_json
      end

      private

      def chart
        @chart ||= if params[:date].present?
                     Chart.where(chart_type: chart_type).find_by!(date: params[:date])
                   else
                     Chart.where(chart_type: chart_type).order(date: :desc).first!
                   end
      end

      def chart_positions
        @chart_positions ||= chart.chart_positions
                               .includes(positianable: :artists)
                               .order(position: :asc)
                               .paginate(page: params[:page], per_page: 24)
      end

      def searched_chart_positions
        @searched_chart_positions ||= chart.chart_positions
                                        .joins('INNER JOIN songs ON songs.id = chart_positions.positianable_id')
                                        .where(positianable_type: 'Song')
                                        .where('songs.search_text ILIKE ?', "%#{params[:search_term]}%")
                                        .includes(positianable: :artists)
                                        .order(position: :asc)
                                        .paginate(page: params[:page], per_page: 24)
      end

      def previous_positions
        @previous_positions ||= begin
          previous_chart = Chart.where(chart_type: chart_type)
                             .where('date < ?', chart.date)
                             .order(date: :desc)
                             .first
          return {} unless previous_chart

          previous_chart.chart_positions.pluck(:positianable_id, :position).to_h
        end
      end

      def chart_type
        params[:type].presence || 'songs'
      end

      def chart_metadata
        { chart_date: chart.date, chart_type: chart.chart_type }
      end
    end
  end
end
