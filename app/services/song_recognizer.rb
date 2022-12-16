# frozen_string_literal: true

require 'resolv'
require 'fuzzystringmatch'

class SongRecognizer
  attr_reader :audio_stream, :result, :title, :artist_name

  def initialize(radio_station)
    @radio_station = radio_station
    output_file = @radio_station.audio_file_path
    @audio_stream = AudioStream::Mp3.new(@radio_station.stream_url, output_file)
    @api_artists, @api_title = scrapper_song
  end

  def recognized?
    audio_stream.capture
    response = make_request
    audio_stream.delete_file
    handle_response(response)
  end

  private

  def make_request
    url = URI("#{ENV['SONG_RECOGNIZER_URL']}/radio_station/#{@radio_station.audio_file_name}")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = Rails.env.production?
    request = Net::HTTP::Get.new(url)
    http.request(request)
  end

  def handle_response(response)
    @result = JSON.parse(response.body).with_indifferent_access
    if response.code == '200'
      @title = result.dig(:result, :track, :title)
      @artist_name = result.dig(:result, :track, :subtitle)
      SongRecognizerLog.create(
        radio_station: @radio_station,
        song_match:,
        recognizer_song_fullname: "#{@artist_name} - #{@title}",
        api_song_fullname: "#{@api_artists} - #{@api_title}",
        result: @result
      )
      true
    else
      false
    end
  end

  def song_match
    jarow = FuzzyStringMatch::JaroWinkler.create(:pure)
    jarow.getDistance("#{@artist_name} #{@title}", "#{@api_artists} #{@api_title}")
  end

  def scrapper_song
    scrapper = TrackScrapper.new(@radio_station)
    return false unless scrapper.latest_track

    [scrapper.artist_name, scrapper.title]
  end
end
