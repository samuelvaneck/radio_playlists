# frozen_string_literal: true

class AudioStream
  attr_reader :command, :output_file, :url, :stream_title

  def initialize(url, output_file)
    @url = url
    @output_file = output_file
  end

  def capture
    Rails.logger.info "Caputing stream command #{command}"
    Open3.popen3(*command) do |_stdin, stdout, stderr, _wait_thr|
      Rails.logger.info "stdout: #{stdout.read}"
      Rails.logger.info "stderr: #{stderr.read}"
    end
  end

  def delete_file
    File.delete(@output_file) if File.exist?(@output_file)
  end
end
