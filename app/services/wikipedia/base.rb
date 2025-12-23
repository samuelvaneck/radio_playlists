# frozen_string_literal: true

module Wikipedia
  class Base
    BASE_URL = 'https://en.wikipedia.org'

    private

    def make_request(path)
      full_path = "/api/rest_v1#{path}"
      Rails.cache.fetch(cache_key(full_path), expires_in: 24.hours) do
        response = connection.get(full_path)
        response.body
      end
    rescue StandardError => e
      ExceptionNotifier.notify_new_relic(e)
      Rails.logger.error("Wikipedia API error: #{e.message}")
      nil
    end

    def connection
      @connection ||= Faraday.new(url: BASE_URL) do |conn|
        conn.response :json
      end
    end

    def cache_key(path)
      "wikipedia:#{path}"
    end
  end
end
