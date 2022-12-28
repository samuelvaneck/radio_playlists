# frozen_string_literal: true

require 'resolv'
require 'fuzzystringmatch'

class SongRecognizer
  attr_reader :audio_stream, :result, :title, :artist_name, :broadcast_timestamp, :spotify_url, :isrc

  def initialize(radio_station)
    @radio_station = radio_station
    @output_file = @radio_station.audio_file_path
    @audio_stream = set_audio_stream
    @broadcast_timestamp = Time.zone.now
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

    @spotify_url = set_spotify_url
    @isrc = @result.dig(:track, :isrc)
    @title = @result.dig(:track, :title)
    @artist_name = @result.dig(:track, :subtitle)
    true
  rescue StandardError => e
    Rails.logger.error "SongRecognizer error: #{e.message}"
    false
  end

  def set_audio_stream
    extension = @radio_station.stream_url.split(/\.|-/).last
    "AudioStream::#{extension.camelcase}".constantize.new(@radio_station.stream_url, @output_file)
  end

  def set_spotify_url
    spotify_provider = @result.dig(:track, :hub, :providers).select { |p| p[:type] == 'SPOTIFY' }
    spotify_provider.dig(0, :actions, 0, :uri)
  end
end
