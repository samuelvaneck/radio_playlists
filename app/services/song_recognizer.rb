# frozen_string_literal: true

require 'resolv'

# SongRecognizer uses SongRec (Shazam audio fingerprinting) to identify songs from radio streams.
#
# == Shazam Response Structure
#
# The full response is stored in SongImportLog#recognized_raw_response for debugging.
# Below is a reference of available fields in the Shazam response:
#
# === Currently Extracted Fields
#   track.title        → title (song title)
#   track.subtitle     → artist_name
#   track.isrc         → isrc_code
#   track.hub.providers[type=SPOTIFY].actions[0].uri → spotify_url
#
# === Available But Not Yet Extracted
#   track.key                           - Shazam track ID (e.g., "154067072")
#   track.url                           - Shazam track URL
#   track.genres.primary                - Genre (e.g., "Pop")
#   track.images.coverart               - Album artwork URL (400x400)
#   track.images.coverarthq             - High-quality album artwork
#   track.images.background             - Artist background image (800x800)
#   track.sections[0].metadata          - Array containing:
#                                           - Album name (title: "Album")
#                                           - Record label (title: "Label")
#                                           - Release year (title: "Released")
#   hub.actions[0].id                   - Apple Music track ID
#   track.albumadamid                   - Apple Music album ID
#   hub.explicit                        - Explicit content flag (boolean)
#   hub.providers[type=YOUTUBEMUSIC]    - YouTube Music search URL
#   hub.providers[type=DEEZER]          - Deezer search URL
#   matches[0].offset                   - Match offset in audio (seconds)
#   matches[0].timeskew                 - Time skew of match
#
# === Example Response Structure
#   {
#     "tagid": "uuid",
#     "track": {
#       "key": "154067072",
#       "title": "Nothing Really Matters",
#       "subtitle": "Mr. Probz",
#       "isrc": "NLB8R1400010",
#       "genres": { "primary": "Pop" },
#       "images": { "coverart": "...", "background": "..." },
#       "sections": [{ "metadata": [{ "title": "Album", "text": "..." }, ...] }],
#       "hub": { "providers": [...], "explicit": false }
#     },
#     "matches": [{ "offset": 155.93, ... }]
#   }
#
class SongRecognizer
  class RecognitionError < StandardError; end
  class RateLimitError < RecognitionError; end

  RATE_LIMIT_PATTERNS = [
    /rate limit/i,
    /too many requests/i,
    /429/,
    /retry after/i
  ].freeze

  attr_reader :audio_stream, :result, :title, :artist_name, :broadcasted_at, :spotify_url, :isrc_code

  # @param radio_station [RadioStation] The radio station to capture audio from
  # @param audio_stream [AudioStream, nil] Optional pre-captured audio stream (skips capture if provided)
  # @param skip_cleanup [Boolean] If true, don't delete the audio file after recognition (for shared use)
  def initialize(radio_station, audio_stream: nil, skip_cleanup: false)
    @radio_station = radio_station
    @output_file = @radio_station.audio_file_path
    @audio_stream = audio_stream || set_audio_stream
    @broadcasted_at = Time.zone.now
    @skip_capture = audio_stream.present?
    @skip_cleanup = skip_cleanup
  end

  def recognized?
    audio_stream.capture unless @skip_capture
    response = run_song_recognizer
    handle_response(response)
  rescue RateLimitError => e
    Rails.logger.warn "SongRecognizer rate limited for #{@radio_station.name}: #{e.message}"
    false
  rescue RecognitionError => e
    Rails.logger.error "SongRecognizer failed for #{@radio_station.name}: #{e.message}"
    false
  rescue StandardError => e
    Rails.logger.error "SongRecognizer unexpected error for #{@radio_station.name}: #{e.class} - #{e.message}"
    false
  ensure
    audio_stream.delete_file unless @skip_cleanup
  end

  private

  def run_song_recognizer
    raise RecognitionError, "Audio file not found: #{@output_file}" unless File.exist?(@output_file)

    Open3.popen3('songrec', 'audio-file-to-recognized-song', @output_file.to_s) do |_stdin, stdout, stderr, _wait_thr|
      output = stdout.read
      error = stderr.read
      output.presence || error
    end
  end

  def handle_response(response)
    validate_response!(response)

    @result = JSON.parse(response)&.with_indifferent_access
    return false if @result[:matches].blank?

    @spotify_url = set_spotify_url
    @isrc_code = @result.dig(:track, :isrc)
    @title = @result.dig(:track, :title)
    @artist_name = @result.dig(:track, :subtitle)
    true
  rescue JSON::ParserError
    raise RecognitionError, "Invalid JSON response: #{response.truncate(200)}"
  end

  def validate_response!(response)
    return if response.blank?

    if rate_limit_error?(response)
      raise RateLimitError, response.truncate(200)
    elsif error_response?(response)
      raise RecognitionError, response.truncate(200)
    end
  end

  def rate_limit_error?(response)
    RATE_LIMIT_PATTERNS.any? { |pattern| response.match?(pattern) }
  end

  def error_response?(response)
    response.start_with?('Error:', 'error:') || response.match?(/\A\s*Error/i)
  end

  def set_audio_stream
    extension = @radio_station.direct_stream_url.split(/\.|-/).last
    if extension.match?(/m3u8/)
      AudioStream::M3u8.new(@radio_station.direct_stream_url, @output_file)
    else
      AudioStream::Mp3.new(@radio_station.direct_stream_url, @output_file)
    end
  end

  def set_spotify_url
    spotify_provider = @result.dig(:track, :hub, :providers).select { |p| p[:type] == 'SPOTIFY' }
    spotify_provider.dig(0, :actions, 0, :uri)
  end
end
