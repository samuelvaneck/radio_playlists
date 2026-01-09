# frozen_string_literal: true

module Deezer
  class Base
    ARTIST_SIMILARITY_THRESHOLD = 80
    TITLE_SIMILARITY_THRESHOLD = 70
    BASE_URL = 'https://api.deezer.com'

    include CircuitBreakable

    circuit_breaker_for :deezer

    attr_reader :args

    def initialize(args = {})
      @args = args
    end

    def make_request(url)
      with_circuit_breaker do
        with_exponential_backoff(max_attempts: 3, base_delay: 1) do
          response = connection.get(url)
          handle_rate_limit_response(response)
          response.body
        end
      end
    rescue StandardError => e
      ExceptionNotifier.notify_new_relic(e)
      Rails.logger.error(e.message)
      nil
    end

    private

    def connection
      Faraday.new(url: BASE_URL) do |conn|
        conn.options.timeout = 15
        conn.options.open_timeout = 5
        conn.response :json
      end
    end

    def artist_distance(item_artist_name)
      (JaroWinkler.similarity(item_artist_name.to_s.downcase, args[:artists].to_s.downcase) * 100).to_i
    end

    def title_distance(item_title)
      (JaroWinkler.similarity(item_title.to_s.downcase, args[:title].to_s.downcase) * 100).to_i
    end
  end
end
