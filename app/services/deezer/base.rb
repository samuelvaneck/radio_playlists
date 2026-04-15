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
          parse_response_body(response)
        end
      end
    rescue StandardError => e
      ExceptionNotifier.notify(e)
      Rails.logger.error(e.message)
      nil
    end

    private

    def parse_response_body(response)
      return response.body if response.body.is_a?(Hash)
      return JSON.parse(response.body) if response.body.is_a?(String) && response.body.start_with?('{', '[')

      Rails.logger.error("Deezer API returned non-JSON response: #{response.body.to_s[0..100]}")
      nil
    end

    def connection
      @connection ||= Faraday.new(url: BASE_URL) do |conn|
        conn.options.timeout = 15
        conn.options.open_timeout = 5
        conn.response :json
      end
    end

    def artist_distance(item_artist_name)
      scraped_names = split_artist_string(args[:artists].to_s).sort_by(&:downcase)
      api_names = split_artist_string(item_artist_name.to_s).sort_by(&:downcase)

      (JaroWinkler.similarity(api_names.join(' ').downcase, scraped_names.join(' ').downcase) * 100).to_i
    end

    def split_artist_string(artist_string)
      regex = Regexp.new(Song::MULTIPLE_ARTIST_REGEX, Regexp::IGNORECASE)
      if artist_string.match?(regex)
        artist_string.split(regex).map(&:strip).reject(&:blank?)
      else
        [artist_string]
      end
    end

    def title_distance(item_title)
      (JaroWinkler.similarity(item_title.to_s.downcase, args[:title].to_s.downcase) * 100).to_i
    end
  end
end
