# frozen_string_literal: true

require 'resolv'

class SongRecognizer
  attr_reader :audio_stream, :result, :title, :artist_name, :broadcast_timestamp, :spotify_url, :isrc_code

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
    @isrc_code = @result.dig(:track, :isrc)
    @title = @result.dig(:track, :title)
    @artist_name = @result.dig(:track, :subtitle)
    create_song_recognizer_log
    true
  rescue StandardError => e
    Rails.logger.error "SongRecognizer error: #{e.message}"
    false
  end

  def set_audio_stream
    extension = @radio_station.stream_url.split(/\.|-/).last
    "AudioStream::#{extension.camelcase}".constantize.new(@radio_station.stream_url, @output_file)
  end

  def create_song_recognizer_log
    SongRecognizerLog.create(
      radio_station: @radio_station,
      recognizer_song_fullname: "#{@artist_name} - #{@title}",
      api_song_fullname: "#{@audio_stream.stream_artist} - #{@audio_stream.stream_title}",
      song_match:
    )
  end

  def set_spotify_url
    spotify_provider = @result.dig(:track, :hub, :providers).select { |p| p[:type] == 'SPOTIFY' }
    spotify_provider.dig(0, :actions, 0, :uri)
  end

  def song_match
    full_result = "#{@result.dig(:track, :subtitle)} #{@result.dig(:track, :title)}"
    full_stream = "#{@audio_stream.stream_artist} #{@audio_stream.stream_title}"
    (JaroWinkler.distance(full_result, full_stream) * 100).to_i
  end

  # def set_title
  #   result_title = @result.dig(:track, :title)
  #   jarow = FuzzyStringMatch::JaroWinkler.create(:pure)
  #   distance = (jarow.getDistance(result_title, @audio_stream.stream_title) * 100).to_i
  #   distance > 80 ? result_title : @audio_stream.stream_title
  # end
  #
  # def set_artist_name
  #   result_artist = @result.dig(:track, :subtitle)
  #   jarow = FuzzyStringMatch::JaroWinkler.create(:pure)
  #   distance = (jarow.getDistance(result_artist, @audio_stream.stream_artist) * 100).to_i
  #   distance > 80 ? result_artist : @audio_stream.stream_artist
  # end
end
