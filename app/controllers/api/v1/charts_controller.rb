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
        render json: AutocompleteSongSerializer.new(autocomplete_songs)
                       .serializable_hash
                       .merge(pagination_data(autocomplete_songs))
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
                                        .where('word_similarity(?, songs.search_text) > 0.3', params[:search_term])
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

      def autocomplete_songs
        song_ids = chart.chart_positions.where(positianable_type: 'Song').pluck(:positianable_id)

        @autocomplete_songs ||= Song.where(id: song_ids)
                                  .search_by_text(params[:q])
                                  .select(:id, :title, :spotify_artwork_url)
                                  .includes(:artists)
                                  .paginate(page: params[:page], per_page: autocomplete_limit)
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
