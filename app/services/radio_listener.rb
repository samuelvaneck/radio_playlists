# frozen_string_literal: true

class RadioListener
  attr_reader :artist_name, :title, :spotify_url, :isrc_code

  def initialize(radio_station:)
    @radio_station = radio_station
  end

  def listen
    response = connection.post('/listen') do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = { url: @radio_station.direct_stream_url }.to_json
    end

    if response.success?
      return false if response.body.dig('result', 'song').blank?

      @artist_name = response.body.dig('result', 'song', 'artist')
      @title = response.body.dig('result', 'song', 'title')
      @spotify_url = response.body.dig('result', 'song', 'spotify_url')
      @isrc_code = response.body.dig('result', 'song', 'isrc')
      true
    else
      Rails.logger.error "RadioListener error: #{response.status} - #{response.body}"
      false
    end
  rescue Faraday::Error => e
    Rails.logger.error("RadioListener connection error: #{e.message}")
    false
  end

  private

  def radio_listener_url
    ENV['RADIO_LISTENER_URL']
  end

  def connection
    @connection ||= Faraday.new(url: radio_listener_url) do |conn|
      conn.request :json
      conn.response :json
    end
  end
end
