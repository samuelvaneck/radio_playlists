# frozen_string_literal: true

module Wikipedia
  class Base
    DEFAULT_LANGUAGE = 'en'
    SUPPORTED_LANGUAGES = %w[en nl de fr es it pt pl ru ja zh].freeze

    include CircuitBreakable

    circuit_breaker_for :wikipedia

    def initialize(language: DEFAULT_LANGUAGE)
      @language = SUPPORTED_LANGUAGES.include?(language) ? language : DEFAULT_LANGUAGE
    end

    private

    attr_reader :language

    def base_url
      "https://#{language}.wikipedia.org"
    end

    def make_rest_request(path)
      full_path = "/api/rest_v1#{path}"
      Rails.cache.fetch(cache_key(full_path), expires_in: 24.hours) do
        with_circuit_breaker do
          response = connection.get(full_path)
          handle_rate_limit_response(response)
          response.body
        end
      end
    rescue StandardError => e
      ExceptionNotifier.notify_new_relic(e)
      Rails.logger.error("Wikipedia API error: #{e.message}")
      nil
    end

    def make_mediawiki_request(params)
      Rails.cache.fetch(cache_key("mediawiki:#{params.values.join(':')}"), expires_in: 24.hours) do
        with_circuit_breaker do
          response = connection.get('/w/api.php') do |req|
            req.params = default_mediawiki_params.merge(params)
          end
          handle_rate_limit_response(response)
          response.body
        end
      end
    rescue StandardError => e
      ExceptionNotifier.notify_new_relic(e)
      Rails.logger.error("Wikipedia API error: #{e.message}")
      nil
    end

    def connection
      @connection ||= Faraday.new(url: base_url) do |conn|
        conn.options.timeout = 10
        conn.options.open_timeout = 5
        conn.response :json
      end
    end

    def default_mediawiki_params
      {
        action: 'query',
        format: 'json',
        formatversion: 2
      }
    end

    def cache_key(path)
      "wikipedia:#{language}:#{path}"
    end
  end
end
