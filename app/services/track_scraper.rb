# frozen_string_literal: true

require 'nokogiri'
require 'open-uri'
require 'net/http'

class TrackScraper
  attr_reader :artist_name, :title, :broadcast_timestamp, :spotify_url, :isrc_code

  def initialize(radio_station)
    @radio_station = radio_station
  end

  private

  def make_request(additional_headers = nil)
    uri = URI @radio_station.url
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', open_timeout: 3, read_timeout: 3) do |http|
      headers = { 'Content-Type': 'application/json' }
      headers.merge!(additional_headers) if additional_headers.present?
      request = Net::HTTP::Get.new(uri, headers)
      response = http.request(request)
      response.code == '200' ? response.body : []
    end
  end
end
