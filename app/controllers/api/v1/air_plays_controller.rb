# frozen_string_literal: true

module Api
  module V1
    class AirPlaysController < ApiController
      PER_PAGE = 12
      COUNT_CACHE_TTL = 5.minutes
      HTTP_CACHE_TTL = 60.seconds

      def index
        expires_in HTTP_CACHE_TTL, public: true
        render json: AirPlaySerializer.new(air_plays)
                       .serializable_hash
                       .merge(pagination_data(air_plays))
                       .to_json
      end

      private

      def air_plays
        @air_plays ||= AirPlay.preload(:radio_station, song: :artists)
                         .last_played(params)
                         .paginate(page: params[:page], per_page: PER_PAGE, total_entries: cached_total_entries)
      end

      def cached_total_entries
        Rails.cache.fetch(count_cache_key, expires_in: COUNT_CACHE_TTL) do
          AirPlay.last_played(params).unscope(:order, :group).count
        end
      end

      def count_cache_key
        key_params = params.except(:page, :format, :controller, :action).to_unsafe_h.sort.to_h
        "air_plays:count:#{Digest::SHA256.hexdigest(key_params.to_json)}"
      end
    end
  end
end
