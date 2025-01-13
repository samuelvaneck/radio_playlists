module Youtube
  class Search
    BASE_URL = 'https://www.googleapis.com/youtube/v3/search'
    API_KEY = ENV['YOUTUBE_API_KEY']

    def initialize(args)
      @args = args
    end
    def make_request
      url = URI("#{BASE_URL}?part=#{part}&key=#{API_KEY}&type=#{type}&videoCategoryId=#{video_category_id}&q=#{query}")
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

