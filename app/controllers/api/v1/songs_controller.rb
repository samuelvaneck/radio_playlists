# frozen_string_literal: true

module Api
  module V1
    class SongsController < ApiController
      before_action :song, only: %i[show graph_data time_analytics]

      def index
        render json: SongSerializer.new(songs)
                                   .serializable_hash
                                   .merge(pagination_data(songs))
                                   .to_json
      end

      def show
        render json: SongSerializer.new(song).serializable_hash.to_json
      end

      def graph_data
        render json: song.graph_data(params[:time] || params[:start_time])
      end

      def chart_positions
        song.update_chart_positions if song.update_cached_positions?

        render json: song.reload.cached_chart_positions.presence || []
      end

      # GET /api/v1/songs/:id/time_analytics
      #
      # Parameters:
      #   - radio_station_ids[] (optional): Filter by specific radio stations
      #   - weeks (optional, default: 4): Number of weeks for trend analysis
      #
      # Response:
      # {
      #   "peak_play_times": {
      #     "peak_hour": 8,
      #     "peak_day": 1,
      #     "peak_day_name": "Monday",
      #     "hourly_distribution": { "8": 5, "14": 3 },
      #     "daily_distribution": { "Monday": 10, "Tuesday": 8 }
      #   },
      #   "play_frequency_trend": {
      #     "trend": "rising",
      #     "trend_percentage": 25.5,
      #     "weekly_counts": { "2024-01-01": 5 },
      #     "first_period_avg": 4.0,
      #     "second_period_avg": 5.0
      #   },
      #   "lifecycle_stats": {
      #     "first_play": "2024-01-01T10:00:00Z",
      #     "last_play": "2024-12-01T15:00:00Z",
      #     "total_plays": 150,
      #     "days_since_first_play": 335,
      #     "days_since_last_play": 7,
      #     "days_active": 335,
      #     "unique_days_played": 120,
      #     "average_plays_per_day": 0.45,
      #     "play_consistency": 35.8
      #   }
      # }
      def time_analytics
        render json: {
          peak_play_times: song.peak_play_times_summary(radio_station_ids: radio_station_ids),
          play_frequency_trend: song.play_frequency_trend(weeks: weeks_param, radio_station_ids: radio_station_ids),
          lifecycle_stats: song.lifecycle_stats(radio_station_ids: radio_station_ids)
        }
      end

      private

      def songs
        @songs ||= Song.most_played(params).paginate(page: params[:page], per_page: 24)
      end

      def song
        @song ||= Song.find params[:id]
      end

      def radio_station_ids
        return if params[:radio_station_ids].blank?

        Array(params[:radio_station_ids]).map(&:to_i)
      end

      def weeks_param
        params[:weeks].present? ? params[:weeks].to_i : 4
      end
    end
  end
end
