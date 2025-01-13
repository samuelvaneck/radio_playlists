module Youtube
  class Search
    BASE_URL = 'https://www.googleapis.com/youtube/v3/search'
    API_KEY = ENV['YOUTUBE_API_KEY']

    def initialize(args)
      @args = args
    end
    def make_request
      url = URI("#{BASE_URL}?part=snippet&key=#{API_KEY}&type=video&videoCategoryId=10&q=#{query}")
      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true
      request = Net::HTTP::Get.new(url)
      hande_response(https.request(request))
    rescue StandardError => e
      Rails.logger.error(e.message)
      ExceptionNotifier.notify_new_relic(e)
      []
    end

    private

    def query
      ERB::Util.url_encode("#{@args[:artists]} #{@args[:title]} official music video")
    end

    def hande_response(response)
      case response.code.to_i
      when 200
        JSON(response.body)
      else
        Rails.logger.error("Youtube API failed with status: #{response.code}")
        []
      end
    end
  end
end

