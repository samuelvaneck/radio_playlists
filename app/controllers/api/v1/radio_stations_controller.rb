# frozen_string_literal: true

module Api
  module V1
    class RadioStationsController < ApiController
      include ActionController::Live

      rate_limit to: 5, within: 1.minute, by: -> { request.remote_ip }, only: :stream_proxy, name: 'stream-proxy',
                 with: -> { render json: { error: 'Rate limit exceeded' }, status: :too_many_requests }

      skip_before_action :authenticate_client!, only: %i[stream_proxy widget sound_profile sentiment_trend]
      before_action :set_radio_station, only: %i[show status data classifiers stream_proxy bar_chart_race
                                                 widget sound_profile sentiment_trend diversity_metrics exposure_saturation]

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

        uri = URI.parse(url)
        return head :forbidden unless uri.scheme == 'https'
        return head :forbidden if private_ip?(uri.host)

        response.headers['Content-Type'] = 'audio/mpeg'

        if m3u8_stream?(url)
          stream_audio_via_ffmpeg(url)
        else
          stream_audio(url)
        end
      rescue RuntimeError
        head :forbidden
      ensure
        response.stream.close
      end

      def bar_chart_race
        return render json: { error: 'Period or start_time parameter is required' }, status: :bad_request if time_param_blank?

        race = BarChartRace.for(type: params[:type], radio_station: @radio_station, params: params)

        render json: { data: race.frames, meta: race.meta }.to_json
      end

      def release_date_graph
        return render json: { error: 'Period or start_time parameter is required' }, status: :bad_request if time_param_blank?

        render json: RadioStation.release_date_graph(params)
      end

      def widget
        render json: @radio_station.widget_data
      end

      def sound_profile
        render json: { data: @radio_station.sound_profile(
          start_time: parse_time_param(:start_time),
          end_time: parse_time_param(:end_time)
        ) }.to_json
      end

      def sentiment_trend
        render json: { data: @radio_station.sentiment_trend(period: params[:period]) }.to_json
      end

      def diversity_metrics
        calculator = PlaylistDiversityCalculator.new(
          radio_station: @radio_station,
          start_time: parse_time_param(:start_time),
          end_time: parse_time_param(:end_time)
        )

        render json: { data: calculator.calculate }.to_json
      end

      def exposure_saturation
        calculator = ExposureSaturationCalculator.new(
          radio_station: @radio_station,
          start_time: parse_time_param(:start_time),
          end_time: parse_time_param(:end_time)
        )

        render json: { data: calculator.calculate }.to_json
      end

      def seasonal_audio_trends
        calculator = SeasonalAudioTrendCalculator.new(
          radio_station_ids: params[:radio_station_ids]&.map(&:to_i),
          start_time: parse_time_param(:start_time),
          end_time: parse_time_param(:end_time)
        )

        render json: { data: calculator.calculate }.to_json
      end

      private

      def set_radio_station
        @radio_station = if params[:id].to_i.to_s == params[:id]
                           RadioStation.find(params[:id])
                         else
                           RadioStation.find_by!(slug: params[:id])
                         end
      end

      def stream_audio(url, redirect_limit = 5)
        raise 'Too many redirects' if redirect_limit.zero?

        uri = URI.parse(url)
        raise 'Only HTTPS URLs are allowed' unless uri.scheme == 'https'
        raise 'Invalid redirect target' if private_ip?(uri.host)

        Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
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

      def stream_audio_via_ffmpeg(url)
        cmd = [
          'ffmpeg',
          '-reconnect', '1',
          '-reconnect_streamed', '1',
          '-reconnect_delay_max', '30',
          '-re',
          '-i', url,
          '-codec:a', 'libmp3lame',
          '-f', 'mp3',
          'pipe:1'
        ]
        Open3.popen3(*cmd) do |_stdin, stdout, _stderr, wait_thr|
          while (chunk = stdout.read(8192))
            break if chunk.empty?

            response.stream.write(chunk)
          end
          wait_thr.value
        end
      end

      def m3u8_stream?(url)
        url.match?(/m3u8/i)
      end

      def private_ip?(host)
        ip = Resolv.getaddress(host)
        addr = IPAddr.new(ip)
        addr.loopback? || addr.private? || addr.link_local?
      rescue Resolv::ResolvError
        true
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
