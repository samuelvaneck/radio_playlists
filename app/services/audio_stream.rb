# frozen_string_literal: true

class AudioStream
  attr_reader :command, :output_file, :url, :stream_title, :stream_artist

  def initialize(url, output_file)
    @url = url
    @output_file = output_file
    @stdout, @stderr, @stream_title, @stream_artist = nil
  end

  def capture
    Rails.logger.info "Caputing stream command #{command}"
    Open3.popen3(*command) do |_stdin, stdout, stderr, _wait_thr|
      @stdout = stdout.read
      @stderr = stderr.read
    end
    utf8_stream_title = convert_stderr_to_utf8
    return if utf8_stream_title.blank?

    @stream_artist, @stream_title = utf8_stream_title.split(':')&.[](1)&.split('-')
    @stream_artist.strip! if @stream_artist.present?
    @stream_title.strip! if @stream_title.present?
  end

  def delete_file
    File.delete(@output_file) if File.exist?(@output_file)
  end

  def convert_stderr_to_utf8
    detection = CharlockHolmes::EncodingDetector.detect(@stderr)
    utf8_encoded_content = CharlockHolmes::Converter.convert(@stderr, detection[:encoding], 'UTF-8')
    utf8_encoded_content.lines.grep(Regexp.new('StreamTitle'))[0]
  end
end
