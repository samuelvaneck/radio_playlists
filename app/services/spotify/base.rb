module Spotify
  class Base
    attr_reader :args

    def initialize(args)
      @args = args
    end

    def make_request(url)
      attempts ||= 1
      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true
      request = Net::HTTP::Get.new(url)
      request['Authorization'] = "Bearer #{token}"
      request['Content-Type'] = 'application/json'

      JSON(https.request(request).body)
    rescue StandardError => e
      if attempts < 3
        attempts += 1
        retry
      else
        Sentry.capture_exception(e)
        nil
      end
    end

    private def token
      Spotify::Token.new.get_token
    end
  end
end
