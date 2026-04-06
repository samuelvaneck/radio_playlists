# frozen_string_literal: true

require 'nokogiri'
require 'open-uri'
require 'net/http'

class TrackScraper
  attr_reader :artist_name, :title, :broadcasted_at, :spotify_url, :isrc_code, :raw_response

  def initialize(radio_station)
    @radio_station = radio_station
    @raw_response = {}
  end

  private

  def make_request(additional_headers = nil)
    response = connection.get(@radio_station.url) do |req|
      req.headers['Content-Type'] = 'application/json'
      req.headers.merge!(additional_headers) if additional_headers
    end
    handle_response(response)
  end

  def connection
    Faraday.new(@radio_station.url) do |conn|
      conn.options.timeout = 15
      conn.options.open_timeout = 5
      conn.request :retry, max: 2, interval: 0.5, backoff_factor: 2,
                           exceptions: [Faraday::ConnectionFailed, Faraday::TimeoutError, Faraday::SSLError]
      conn.response :json
    end
  end

  def handle_response(response)
    if response.success? && response.body.present?
      response.body.with_indifferent_access
    else
      Rails.logger.error("Error fetching data from #{@radio_station.name}: #{response.status}") unless response.success?
      nil
    end
  end
end
