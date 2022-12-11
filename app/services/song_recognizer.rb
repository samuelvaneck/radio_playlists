# frozen_string_literal: true

class SongRecognizer
  attr_reader :audio_stream, :result

  ENDPOINT =

  def initialize(radio_station)
    @radio_station = radio_station
    output_file = Rails.root.join("tmp/#{radio_station.name}.mp3")
    @audio_stream = AudioStreamFfmpeg.new(radio_station.stream_url, output_file)
  end

  def recognize
    audio_stream.capture
    response = make_request
    handle_response(response)
  end

  private

  def make_request
    url = URI.new("#{ENV['SONG_RECOGNIZER_URL']}/radio_station/#{radio_station.name}")
    http = Net::HTTP.new(url.host, url.port)
    request = Net::HTTP::Post.new(url)
    response = http.request(request)
    handle_response(response)
  end

  def handle_response(response)
    @result = JSON.parse(response.body)
    response.code == 200
  end
end
