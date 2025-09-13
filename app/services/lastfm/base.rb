# frozen_string_literal: true

module Lastfm
  class Base
    BASE_URL = 'http://ws.audioscrobbler.com/2.0/'.freeze

    def initialize
      @api_key = ENV.fetch('LASTFM_API_KEY', nil)
    end

    def api_key_present?
      @api_key.present?
    end

    private

    def connection
      @connection ||= Faraday.new(url: BASE_URL) do |conn|
        conn.response :json, parser_options: { symbolize_names: false }
        conn.adapter Faraday.default_adapter
      end
    end

    def make_request(params)
      return nil unless @api_key.present?

      params = params.merge(
        api_key: @api_key,
        format: 'json'
      )

      response = connection.get do |req|
        req.params = params
      end

      if response.success?
        response.body
      else
        handle_error(response)
        nil
      end
    rescue Faraday::Error => e
      Rails.logger.error "Last.fm API connection error: #{e.message}"
      nil
    end

    def handle_error(response)
      error_message = if response.body.is_a?(Hash)
                        response.body['message'] || response.body['error']
                      else
                        "HTTP #{response.status}"
                      end

      Rails.logger.error "Last.fm API error: #{error_message}"
    end

    def extract_image(images)
      return nil unless images.is_a?(Array)

      image_by_size = {}
      images.each do |img|
        next unless img.is_a?(Hash) && img['#text'].present?
        image_by_size[img['size']] = img['#text']
      end

      image_by_size['extralarge'] || image_by_size['large'] || 
        image_by_size['medium'] || image_by_size['small'] || 
        image_by_size.values.first
    end
  end
end