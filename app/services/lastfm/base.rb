# frozen_string_literal: true

module Lastfm
  class Base
    BASE_URL = 'https://ws.audioscrobbler.com/2.0/'

    private

    def make_request(params)
      Rails.cache.fetch(cache_key(params), expires_in: 24.hours) do
        response = connection.get do |req|
          req.params = default_params.merge(params)
        end

        response.body
      end
    rescue StandardError => e
      ExceptionNotifier.notify_new_relic(e)
      Rails.logger.error("Lastfm API error: #{e.message}")
      nil
    end

    def connection
      @connection ||= Faraday.new(url: BASE_URL) do |conn|
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
