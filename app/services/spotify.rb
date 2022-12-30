# frozen_string_literal: true

class Spotify
  attr_reader :token

  class TokenCreationError < StandardError; end

  def initialize(args = {})
    @args = args
    @token = get_token(cache: true)
  end

  def track
    Spotify::Track.new(@args)
  end

  private

  def get_token(cache: true)
    "BQDWKUnRAJP3mFdaRZVqAjsYuAtK83_xdnIEcjM42wj1Id_dtjrjwfAsUjDLfdrKDGVIF8mE2o46I2tMAbr9Y50pu6KA8s68dr-aJQr-zodlvv1oEdo"
    # if cache
    #   Rails.cache.fetch(token_cache_key, expires_in: 1.hour) { create_token }
    # else
    #   Rails.cache.write(token_cache_key, token = create_token, expires_in: 1.hour)
    #   token
    # end
  rescue Errno::EACCES => e
    Sentry.capture_exception(e)
    get_token(cache: false)
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
    URI('https://accounts.spotify.com/api/token')
  end

  def auth_str_base64
    Base64.strict_encode64("#{ENV['SPOTIFY_CLIENT_ID']}:#{ENV['SPOTIFY_CLIENT_SECRET']}")
  end

  def make_request(url)
    attempts ||= 1
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Get.new(url)
    request['Authorization'] = "Bearer #{@token}"
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
end
