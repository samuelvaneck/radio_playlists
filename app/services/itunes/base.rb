# frozen_string_literal: true

module Itunes
  class Base
    attr_reader :args

    BASE_URL = 'https://itunes.apple.com'
    DEFAULT_COUNTRY = 'nl'

    def initialize(args = {})
      @args = args
    end

    def make_request(url)
      attempts ||= 1

      Rails.cache.fetch(url.to_s, expires_in: 12.hours) do
        response = connection.get(url)
        response.body
      end
    rescue StandardError => e
      if attempts < 3
        attempts += 1
        retry
      else
        ExceptionNotifier.notify_new_relic(e)
        Rails.logger.error(e.message)
        nil
      end
    end

    private

    def connection
      Faraday.new(url: BASE_URL) do |conn|
        # iTunes API returns 'text/javascript' content type instead of 'application/json'
        conn.response :json, content_type: /\bjson$|\bjavascript$/
      end
    end

    def string_distance(item_string)
      (JaroWinkler.similarity(item_string, "#{args[:artists]} #{args[:title]}") * 100).to_i
    end
  end
end
