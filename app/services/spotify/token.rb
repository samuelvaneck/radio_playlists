module Spotify
  class Token < Base
    class TokenCreationError < StandardError; end

    SPOTIFY_AUTH_URL = 'https://accounts.spotify.com/api/token'.freeze

    attr_reader :cache
    def initialize(cache: true)
      @cache = cache
    end

    def get_token
      if @cache
        Rails.cache.fetch(token_cache_key, expires_in: 1.hour) { create_token }
      else
        create_token
      end
    rescue Errno::EACCES => e
      Sentry.capture_exception(e)
      @cache = false
      get_token
    end

    def create_token
      https = Net::HTTP.new(token_url.host, token_url.port)
      https.use_ssl = true
      request = Net::HTTP::Post.new(token_url)
      request['Authorization'] = "Basic #{auth_str_base64}"
      request['Content-Type'] = 'application/x-www-form-urlencoded'
      request.body = 'grant_type=client_credentials'

      response = https.request(request)
      JSON(response.body)['access_token']
    end

    def token_cache_key
      [:spotify_token]
    end

    def token_url
      URI(SPOTIFY_AUTH_URL)
    end

    def auth_str_base64
      Base64.strict_encode64("#{ENV['SPOTIFY_CLIENT_ID']}:#{ENV['SPOTIFY_CLIENT_SECRET']}")
    end
  end
end
