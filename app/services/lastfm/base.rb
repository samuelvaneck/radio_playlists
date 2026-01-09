# frozen_string_literal: true

module Lastfm
  class Base
    include CircuitBreakable

    circuit_breaker_for :lastfm

    BASE_URL = 'https://ws.audioscrobbler.com/2.0/'

    private

    def make_request(params)
      Rails.cache.fetch(cache_key(params), expires_in: 24.hours) do
        with_circuit_breaker do
          response = connection.get do |req|
            req.params = default_params.merge(params)
          end
          handle_rate_limit_response(response)
          response.body
        end
      end
    rescue StandardError => e
      ExceptionNotifier.notify_new_relic(e)
      Rails.logger.error("Lastfm API error: #{e.message}")
      nil
    end

    def connection
      @connection ||= Faraday.new(url: BASE_URL) do |conn|
        conn.options.timeout = 10
        conn.options.open_timeout = 5
        conn.response :json
      end
    end

    def default_params
      {
        api_key: ENV.fetch('LASTFM_API_KEY', nil),
        format: 'json'
      }
    end

    def cache_key(params)
      "lastfm:#{params.values.join(':')}"
    end
  end
end
