# frozen_string_literal: true

module Lyrics
  class Base
    BASE_URL = 'https://lrclib.net/api/'
    USER_AGENT = 'Airplays/1.0 (https://github.com/samuelvaneck/airplays)'

    include CircuitBreakable

    circuit_breaker_for :lrclib

    private

    def get(path, params = {})
      with_circuit_breaker do
        with_exponential_backoff(max_attempts: 3, base_delay: 1) do
          response = connection.get(path, params)
          handle_rate_limit_response(response)
          response.success? ? response.body : nil
        end
      end
    rescue StandardError => e
      ExceptionNotifier.notify(e)
      Rails.logger.error("[Lyrics] LRCLIB request failed: #{e.class}: #{e.message}")
      nil
    end

    def connection
      @connection ||= Faraday.new(url: BASE_URL, headers: { 'User-Agent' => USER_AGENT }) do |conn|
        conn.options.timeout = 10
        conn.options.open_timeout = 5
        conn.response :json
      end
    end
  end
end
