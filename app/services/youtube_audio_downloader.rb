# frozen_string_literal: true

class YoutubeAudioDownloader
  class DownloadError < StandardError; end

  YOUTUBE_URL_TEMPLATE = 'https://www.youtube.com/watch?v=%<video_id>s'

  attr_reader :youtube_id, :output_file, :duration

  def initialize(youtube_id)
    @youtube_id = youtube_id
    @output_file = nil
    @duration = nil
  end

  def download
    validate_youtube_id!
    @output_file = generate_output_path

    command = build_command
    Rails.logger.info "YoutubeAudioDownloader: Downloading #{youtube_url}"

    output, error, status = Open3.capture3(*command)

    unless status.success?
      Rails.logger.error "YoutubeAudioDownloader failed: #{error}"
      raise DownloadError, "yt-dlp failed: #{error.presence || 'unknown error'}"
    end

    extract_duration(output)
    Rails.logger.info "YoutubeAudioDownloader: Downloaded to #{@output_file} (#{@duration}s)"

    { output_file: @output_file, duration: @duration }
  end

  def cleanup
    return unless @output_file && File.exist?(@output_file)

    File.delete(@output_file)
    Rails.logger.debug "YoutubeAudioDownloader: Cleaned up #{@output_file}"
  end

  private

  def validate_youtube_id!
    raise DownloadError, 'YouTube ID is required' if @youtube_id.blank?
    raise DownloadError, 'Invalid YouTube ID format' unless @youtube_id.match?(/\A[a-zA-Z0-9_-]{11}\z/)
  end

  def generate_output_path
    filename = "youtube_#{@youtube_id}_#{Time.current.to_i}.mp3"
    Rails.root.join('tmp', 'audio', filename).to_s
  end

  def youtube_url
    format(YOUTUBE_URL_TEMPLATE, video_id: @youtube_id)
  end

  def build_command
    [
      'yt-dlp',
      '-x',                          # Extract audio only
      '--audio-format', 'mp3',       # Convert to MP3
      '--audio-quality', '192K',     # Good quality for fingerprinting
      '-o', @output_file,            # Output file path
      '--no-playlist',               # Don't download playlists
      '--no-warnings',               # Suppress warnings
      '--print-json',                # Output metadata as JSON (for duration)
      youtube_url
    ]
  end

  def extract_duration(output)
    json_line = output.lines.find { |line| line.strip.start_with?('{') }
    return unless json_line

    metadata = JSON.parse(json_line)
    @duration = metadata['duration']&.to_i
  rescue JSON::ParserError => e
    Rails.logger.warn "YoutubeAudioDownloader: Could not parse duration: #{e.message}"
  end
end
