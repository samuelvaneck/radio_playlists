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

      def autocomplete
        results = autocomplete_from_chart
        in_chart = results.any?
        results = autocomplete_from_songs unless in_chart

        render json: SongSerializer.new(results)
                       .serializable_hash
                       .merge(in_chart: in_chart)
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

      def autocomplete_from_chart
        latest_songs_chart.chart_positions
          .joins('INNER JOIN songs ON songs.id = chart_positions.positianable_id')
          .where(positianable_type: 'Song')
          .where('songs.search_text ILIKE ?', "%#{params[:q]}%")
          .includes(positianable: :artists)
          .order(position: :asc)
          .limit(autocomplete_limit)
          .map(&:positianable)
      end

      def autocomplete_from_songs
        Song.matching(params[:q])
          .includes(:artists)
          .limit(autocomplete_limit)
      end

      def latest_songs_chart
        @latest_songs_chart ||= Chart.where(chart_type: 'songs').order(date: :desc).first!
      end

      def autocomplete_limit
        [params.fetch(:limit, 10).to_i, 20].min
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
