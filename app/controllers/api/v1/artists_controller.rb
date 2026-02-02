# frozen_string_literal: true

module Api
  module V1
    class ArtistsController < ApiController
      before_action :artist, only: %i[show graph_data songs chart_positions time_analytics air_plays bio]
      def index
        render json: ArtistSerializer.new(artists)
                                     .serializable_hash
                                     .merge(pagination_data(artists))
                                     .to_json
      end

      def show
        render json: ArtistSerializer.new(artist).serializable_hash.to_json
      end

      # GET /api/v1/artists/autocomplete
      #
      # Parameters:
      #   - q (required): Search query string
      #   - limit (optional, default: 10): Maximum number of results (max: 20)
      #
      # Response:
      # {
      #   "data": [
      #     { "id": "1", "type": "artist", "attributes": { "id": 1, "name": "..." } }
      #   ]
      # }
      def autocomplete
        results = Artist.matching(params[:q])
                        .limit(autocomplete_limit)

        render json: ArtistSerializer.new(results).serializable_hash.to_json
      end

      def graph_data
        render json: artist.graph_data(params[:period])
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

      # GET /api/v1/artists/:id/bio
      #
      # Parameters:
      #   - language (optional, default: 'en'): Wikipedia language
      #     Supported: en, nl, de, fr, es, it, pt, pl, ru, ja, zh
      #
      # Example response:
      # {
      #   "bio": {
      #     "summary": "...",
      #     "content": "...",
      #     "description": "Dutch singer",
      #     "url": "https://en.wikipedia.org/wiki/...",
      #     "wikibase_item": "Q27982469",
      #     "thumbnail": { "source": "...", "width": 320, "height": 213 },
      #     "original_image": { "source": "...", "width": 4272, "height": 2848 },
      #     "general_info": {
      #       "date_of_birth": "1984-09-22",
      #       "place_of_birth": "Dedemsvaart",
      #       "nationality": ["Netherlands"],
      #       "genres": ["pop", "rock"],
      #       "occupations": ["singer", "songwriter"],
      #       "official_website": "https://...",
      #       "active_years": { "start": "2008", "end": null }
      #     }
      #   }
      # }
      def bio
        bio_data = Wikipedia::ArtistFinder.new(language: language_param).get_info(artist.name)
        render json: { bio: bio_data }
      end

      private

      def artist_air_plays
        start_time, end_time = AirPlay.time_range_from_params(params, default_period: 'day')

        @artist_air_plays ||= artist.air_plays
                                    .includes(:radio_station, song: :artists)
                                    .played_between(start_time, end_time)
                                    .played_on(radio_station_ids)
                                    .order(broadcasted_at: :desc)
                                    .paginate(page: params[:page], per_page: 24)
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

      def language_param
        params[:language] || 'en'
      end

      def autocomplete_limit
        [params.fetch(:limit, 10).to_i, 20].min
      end
    end
  end
end
