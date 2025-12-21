# frozen_string_literal: true

module Api
  module V1
    class ArtistsController < ApiController
      before_action :artist, only: %i[show graph_data songs chart_positions time_analytics air_plays]
      def index
        render json: ArtistSerializer.new(artists)
                                     .serializable_hash
                                     .merge(pagination_data(artists))
                                     .to_json
      end

      def show
        render json: ArtistSerializer.new(artist).serializable_hash.to_json
      end

      def graph_data
        render json: artist.graph_data(params[:time] || params[:start_time])
      end

      def songs
        render json: SongSerializer.new(artist.songs).serializable_hash.to_json
      end

      # GET /api/v1/artists/:id/chart_positions
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
        render json: artist.chart_positions_for_period(period_param)
      end

      def time_analytics
        render json: {
          peak_play_times: artist.peak_play_times_summary(radio_station_ids: radio_station_ids),
          play_frequency_trend: artist.play_frequency_trend(weeks: weeks_param, radio_station_ids: radio_station_ids),
          lifecycle_stats: artist.lifecycle_stats(radio_station_ids: radio_station_ids)
        }
      end

      # GET /api/v1/artists/:id/air_plays
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
        render json: AirPlaySerializer.new(artist_air_plays)
                                      .serializable_hash
                                      .merge(pagination_data(artist_air_plays))
                                      .to_json
      end

      private

      def artist_air_plays
        @artist_air_plays ||= artist.air_plays
                                    .includes(:radio_station, song: :artists)
                                    .played_between(air_plays_start_time, Time.zone.now)
                                    .played_on(radio_station_ids)
                                    .order(broadcasted_at: :desc)
                                    .paginate(page: params[:page], per_page: 24)
      end

      def air_plays_start_time
        AirPlay.date_from_params(time: params[:period] || 'day', fallback: 1.day.ago)
      end

      def artists
        @artists ||= Artist.most_played(params).paginate(page: params[:page], per_page: 24)
      end

      def artist
        @artist ||= Artist.find params[:id]
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
