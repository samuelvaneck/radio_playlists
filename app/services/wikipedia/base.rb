# frozen_string_literal: true

module Wikipedia
  class Base
    BASE_URL = 'https://en.wikipedia.org'

    private

    def make_rest_request(path)
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

    def make_mediawiki_request(params)
      Rails.cache.fetch(cache_key("mediawiki:#{params.values.join(':')}"), expires_in: 24.hours) do
        response = connection.get('/w/api.php') do |req|
          req.params = default_mediawiki_params.merge(params)
        end
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

    def default_mediawiki_params
      {
        action: 'query',
        format: 'json',
        formatversion: 2
      }
    end

    def cache_key(path)
      "wikipedia:#{path}"
    end
  end
end
