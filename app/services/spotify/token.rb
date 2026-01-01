module Spotify
  class Token < Base
    class TokenGenerationError < StandardError; end

    BASE_URL = 'https://accounts.spotify.com'.freeze
    AUTH_PATH = '/api/token'.freeze

    attr_reader :cache

    def initialize(cache: true)
      super
      @cache = cache
    end

    def token
      if @cache
        Rails.cache.fetch(token_cache_key, expires_in: 1.hour) { generate_token }
      else
        generate_token
      end
    rescue Errno::EACCES, TokenGenerationError => e
      ExceptionNotifier.notify_new_relic(e)
      raise e
    end

    private

    def generate_token
      response = connection.post(AUTH_PATH) do |req|
        req.headers['Authorization'] = "Basic #{auth_str_base64}"
        req.body = 'grant_type=client_credentials'
      rescue Faraday::Error => e
        output_error(e)
        raise TokenGenerationError, 'Failed to create token'
      end

      response.body['access_token']
    end

    def token_cache_key
      [:spotify_token]
    end

    def connection
      Faraday.new(BASE_URL) do |builder|
        builder.options.timeout = 10
        builder.options.open_timeout = 5
        builder.response :json
        builder.request :url_encoded
      end
    end

    def output_error(error)
      ExceptionNotifier.notify_new_relic(error)
      Rails.logger.error(error.response[:body])
      Rails.logger.error(error.response[:status])
    end

    def auth_str_base64
      Base64.strict_encode64("#{ENV['SPOTIFY_CLIENT_ID']}:#{ENV['SPOTIFY_CLIENT_SECRET']}")
    end
  end
end
