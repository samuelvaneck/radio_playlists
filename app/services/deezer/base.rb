# frozen_string_literal: true

module Deezer
  class Base
    attr_reader :args

    BASE_URL = 'https://api.deezer.com'

    def initialize(args = {})
      @args = args
    end

    def make_request(url)
      attempts ||= 1

      response = Rails.cache.fetch(url.to_s, expires_in: 12.hours) do
        connection.get(url).body
      end
      # Deep duplicate to prevent mutation of cached objects
      response.deep_dup
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
        conn.response :json
      end
    end

    def string_distance(item_string)
      (JaroWinkler.similarity(item_string, "#{args[:artists]} #{args[:title]}") * 100).to_i
    end
  end
end
