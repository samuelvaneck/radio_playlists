# frozen_string_literal: true

module Itunes
  class Base
    ARTIST_SIMILARITY_THRESHOLD = 80
    TITLE_SIMILARITY_THRESHOLD = 70

    attr_reader :args

    BASE_URL = 'https://itunes.apple.com'
    DEFAULT_COUNTRY = 'nl'

    def initialize(args = {})
      @args = args
    end

    def make_request(url)
      attempts ||= 1

      response = connection.get(url)
      response.body.is_a?(String) ? JSON.parse(response.body) : response.body
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

    def artist_distance(item_artist_name)
      (JaroWinkler.similarity(item_artist_name.to_s.downcase, args[:artists].to_s.downcase) * 100).to_i
    end

    def title_distance(item_title)
      (JaroWinkler.similarity(item_title.to_s.downcase, args[:title].to_s.downcase) * 100).to_i
    end
  end
end
