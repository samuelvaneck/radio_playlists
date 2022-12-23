# frozen_string_literal: true

require 'resolv'
require 'fuzzystringmatch'

class SongRecognizer
  attr_reader :audio_stream, :result, :title, :artist_name

  def initialize(radio_station)
    @radio_station = radio_station
    @output_file = @radio_station.audio_file_path
    @audio_stream = set_audio_stream
    @api_artists, @api_title = scrapper_song
  end

  def recognized?
    audio_stream.capture
    response = run_song_recognizer
    audio_stream.delete_file
    handle_response(response)
  end

  private

  def run_song_recognizer
    command = "songrec audio-file-to-recognized-song #{@output_file}"
    Open3.popen3(command) do |_stdin, stdout, stderr, _wait_thr|
      output = stdout.read
      error = stderr.read
      output.presence || error
    end
  end

  def handle_response(response)
    @result = JSON.parse(response).with_indifferent_access
    return false if @result[:matches].blank?

    @title = @result.dig(:track, :title)
    @artist_name = @result.dig(:track, :subtitle)
    SongRecognizerLog.create(
      radio_station_id: @radio_station.id,
      song_match:,
      recognizer_song_fullname: "#{@artist_name} - #{@title}",
      api_song_fullname: "#{@api_artists} - #{@api_title}"
    )
    true
  rescue StandardError => e
    Rails.logger.error "SongRecognizer error: #{e.message}"
    false
  end

  def song_match
    jarow = FuzzyStringMatch::JaroWinkler.create(:pure)
    distance = jarow.getDistance("#{@artist_name} #{@title}".downcase, "#{@api_artists} #{@api_title}".downcase)
    (distance * 100).to_i
  end

  def scrapper_song
    scrapper = TrackScrapper.new(@radio_station)
    return false unless scrapper.latest_track

    [scrapper.artist_name, scrapper.title]
  end

  def set_audio_stream
    extension = @radio_station.stream_url.split(/\.|-/).last
    "AudioStream::#{extension.camelcase}".constantize.new(@radio_station.stream_url, @output_file)
  end
end
