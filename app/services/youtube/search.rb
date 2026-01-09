# frozen_string_literal: true

# Args to pass to the Youtube::Search class
# { artists: song.artists.pluck(:name).join(' '), title: song.title }
# E.g. Youtube::Search.new({ artists:'Walking On Cars' title: 'Speeding Cars'}).find_id
#
module Youtube
  class Search
    include CircuitBreakable

    circuit_breaker_for :youtube

    BASE_URL = 'https://www.googleapis.com/youtube/v3/search'.freeze
    API_KEY = ENV['YOUTUBE_API_KEY']

    attr_reader :args

    def initialize(args)
      @args = args
    end

    def find_id
      response = make_request
      return nil if response.blank?

      only_official = Youtube::Filter.new(videos: response['items'], title: @args[:title]).only_official
      only_official_with_same_title = Youtube::Filter.new(videos: only_official, title: @args[:title]).with_same_title

      only_official_with_same_title.dig(0, 'id', 'videoId')
    end

    def make_request
      with_circuit_breaker do
        response = connection.get do |req|
          req.params['part'] = part
          req.params['key'] = API_KEY
          req.params['type'] = type
          req.params['videoCategoryId'] = video_category_id
          req.params['q'] = query
        end
        handle_rate_limit_response(response)
        handle_response(response)
      end
    rescue Faraday::Error => e
      Rails.logger.error(e.message)
      ExceptionNotifier.notify_new_relic(e)
      []
    end
    # def make_request
    #   url = URI("#{BASE_URL}?part=#{part}&key=#{API_KEY}&type=#{type}&videoCategoryId=#{video_category_id}&q=#{query}")
    #   https = Net::HTTP.new(url.host, url.port)
    #   https.use_ssl = true
    #   request = Net::HTTP::Get.new(url)
    #   hande_response(https.request(request))
    # rescue StandardError => e
    #   Rails.logger.error(e.message)
    #   ExceptionNotifier.notify_new_relic(e)
    #   []
    # end

    private

    def connection
      @connection ||= Faraday.new(url: BASE_URL) do |conn|
        conn.options.timeout = 15
        conn.options.open_timeout = 5
      end
    end

    def query
      ERB::Util.url_encode("#{@args[:artists]} #{@args[:title]} official music video")
    end

    # Only search for snippet data. This will include the video title, description, and other metadata
    def part
      'snippet'
    end

    # Only search for videos
    def type
      'video'
    end

    # YouTube vide category ID for music videos
    def video_category_id
      10
    end

    def handle_response(response)
      if response.success?
        JSON.parse(response.body)
      else
        Rails.logger.error("Youtube API failed with status: #{response.status}")
        []
      end
    end
  end
end

