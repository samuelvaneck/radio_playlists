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
        songs = autocomplete_songs
        chart_data = autocomplete_chart_data(songs.map(&:id))

        render json: AutocompleteSongSerializer.new(songs, params: { chart_data: chart_data })
                       .serializable_hash
                       .merge(pagination_data(songs))
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
        Song.matching(params[:q])
          .select('songs.id, songs.title, songs.spotify_artwork_url, MAX(air_plays.created_at) AS last_played_at')
          .left_joins(:air_plays)
          .group('songs.id')
          .order(Arel.sql('MAX(air_plays.created_at) DESC NULLS LAST, COALESCE(songs.popularity, 0) DESC'))
          .includes(:artists)
          .paginate(page: params[:page], per_page: autocomplete_limit)
      end

      def autocomplete_chart_data(song_ids)
        return {} if song_ids.empty?

        latest_chart = Chart.where(chart_type: 'songs').order(date: :desc).first
        return {} unless latest_chart

        in_chart_ids = latest_chart.chart_positions
                         .where(positianable_type: 'Song', positianable_id: song_ids)
                         .pluck(:positianable_id)
                         .to_set

        not_in_chart_ids = song_ids - in_chart_ids.to_a
        last_chart_dates = last_chart_appearance(not_in_chart_ids)

        song_ids.index_with do |song_id|
          {
            in_chart: in_chart_ids.include?(song_id),
            last_chart_date: in_chart_ids.include?(song_id) ? latest_chart.date : last_chart_dates[song_id]
          }
        end
      end

      def last_chart_appearance(song_ids)
        return {} if song_ids.empty?

        ChartPosition.where(positianable_type: 'Song', positianable_id: song_ids)
          .joins(:chart)
          .group(:positianable_id)
          .maximum('charts.date')
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
