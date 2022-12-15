# frozen_string_literal: true

require 'resolv'

class SongRecognizer
  attr_reader :audio_stream, :result, :title, :artist_name

  def initialize(radio_station)
    @radio_station = radio_station
    output_file = Rails.root.join(@radio_station.audio_file_path)
    @audio_stream = AudioStream::Mp3.new(@radio_station.stream_url, output_file)
  end

  def recognized?
    audio_stream.capture
    response = make_request
    audio_stream.delete_file
    handle_response(response)
  end

  private

  def make_request
    ip_address = Resolv.getaddress('song_recognizer')
    url = URI("http://#{ip_address}:8080/radio_station/#{@radio_station.audio_file_name}")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = false
    request = Net::HTTP::Get.new(url)
    http.request(request)
  end

  def handle_response(response)
    @result = JSON.parse(response.body).with_indifferent_access
    if response.code == '200'
      @title = result.dig(:result, :track, :title)
      @artist_name = result.dig(:result, :track, :subtitle)
      true
    else
      false
    end
  end
end
