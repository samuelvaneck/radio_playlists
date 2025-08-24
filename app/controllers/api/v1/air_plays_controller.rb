# frozen_string_literal: true

module Api
  module V1
    class AirPlaysController < ApiController
      def index
        render json: AirPlaySerializer.new(air_plays)
                                      .serializable_hash
                                      .merge(pagination_data(air_plays))
                                      .to_json
      end

      private

      def air_plays
        @air_plays ||= AirPlay.includes([:song, :radio_station])
                              .last_played(params)
                              .paginate(page: params[:page], per_page: 12)
      end
    end
  end
end
