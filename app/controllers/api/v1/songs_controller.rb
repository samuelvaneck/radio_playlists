# frozen_string_literal: true

module Api
  module V1
    class SongsController < ApiController
      before_action :song, only: %i[show graph_data chart_positions time_analytics air_plays]

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

      # GET /api/v1/songs/:id/chart_positions
      #
      # Parameters:
      #   - period (optional, default: 'month'): Time period for chart positions
      #     - 'week': last 7 days
      #     - 'month': last 30 days
      #     - 'year': last 365 days
      #     - 'all': all time
      #
      # Response:
      # [
      #   { "date": "2024-12-01", "position": 5, "counts": 42 },
      #   { "date": "2024-12-02", "position": 3, "counts": 58 },
      #   ...
      # ]
      def chart_positions
        render json: song.chart_positions_for_period(period_param)
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

      # GET /api/v1/songs/:id/air_plays
      #
      # Parameters:
      #   - period (optional, default: 'day'): Time period for air plays
      #     - 'day': last 24 hours
      #     - 'week': last 7 days
      #     - 'month': last 30 days
      #     - 'year': last 365 days
      #     - 'all': all time
      #   - radio_station_ids[] (optional): Filter by specific radio stations
      def air_plays
        render json: AirPlaySerializer.new(song_air_plays)
                                      .serializable_hash
                                      .merge(pagination_data(song_air_plays))
                                      .to_json
      end

      private

      def song_air_plays
        @song_air_plays ||= song.air_plays
                                .includes(:radio_station, song: :artists)
                                .played_between(air_plays_start_time, Time.zone.now)
                                .played_on(radio_station_ids)
                                .order(broadcasted_at: :desc)
                                .paginate(page: params[:page], per_page: 24)
      end

      def air_plays_start_time
        AirPlay.date_from_params(time: params[:period] || 'day', fallback: 1.day.ago)
      end

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

      def period_param
        params[:period] || 'month'
      end
    end
  end
end
