# frozen_string_literal: true

module Api
  module V1
    class RadioStationsController < ApiController
      include ActionController::Live

      before_action :set_radio_station, only: %i[show status data classifiers stream_proxy timeline]

      def index
        render json: RadioStationSerializer.new(RadioStation.all).serializable_hash.to_json
      end

      def show
        render json: RadioStationSerializer.new(@radio_station).serializable_hash.to_json
      end

      def status
        render json: @radio_station.status_data
      end

      def data
        render json: @radio_station.data
      end

      def classifiers
        calculator = RadioStationMusicProfileCalculator.new(
          radio_station: @radio_station,
          hour: params[:hour].presence&.to_i,
          start_time: parse_time_param(:start_time),
          end_time: parse_time_param(:end_time)
        )

        profiles = calculator.calculate
        render json: RadioStationMusicProfileSerializer.new(profiles, radio_station: @radio_station).serializable_hash.to_json
      end

      def last_played_songs
        render json: RadioStation.last_played_songs.to_json
      end

      def new_played_songs
        return render json: { error: 'Period or start_time parameter is required' }, status: :bad_request if time_param_blank?

        render json: RadioStationSongSerializer.new(new_played_items)
                       .serializable_hash
                       .merge(pagination_data(new_played_items))
                       .to_json
      end

      def stream_proxy
        url = @radio_station.direct_stream_url
        return head :bad_request if url.blank?

        response.headers['Access-Control-Allow-Origin'] = '*'
        response.headers['Content-Type'] = 'audio/mpeg'

        stream_audio(url)
      ensure
        response.stream.close
      end

      def timeline
        return render json: { error: 'Period or start_time parameter is required' }, status: :bad_request if time_param_blank?

        timeline = RadioStationTimeline.new(radio_station: @radio_station, params: params)
        paginated = timeline.songs.paginate(page: params[:page], per_page: params[:per_page] || 24)

        render json: SongSerializer.new(paginated, meta: timeline.meta)
                       .serializable_hash
                       .merge(pagination_data(paginated))
                       .to_json
      end

      private

      def set_radio_station
        @radio_station = RadioStation.find params[:id]
      end

      def stream_audio(url, redirect_limit = 5)
        raise 'Too many redirects' if redirect_limit.zero?

        uri = URI.parse(url)
        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
          request = Net::HTTP::Get.new(uri)
          request['User-Agent'] = 'Mozilla/5.0'
          request['Icy-MetaData'] = '0'
          http.request(request) do |res|
            if res.is_a?(Net::HTTPRedirection)
              redirect_url = URI.join(uri, res['location']).to_s
              return stream_audio(redirect_url, redirect_limit - 1)
            end

            res.read_body { |chunk| response.stream.write(chunk) }
          end
        end
      end

      def time_param_blank?
        params[:period].blank? && params[:start_time].blank?
      end

      def parse_time_param(param)
        params[param].present? ? Time.zone.parse(params[param]) : nil
      end

      def new_played_items
        @new_played_items ||= RadioStation.new_songs_played_for_period(params).paginate(page: params[:page], per_page: 24)
      end
    end
  end
end
