# frozen_string_literal: true

class AudioStream
  attr_reader :command, :output_file, :url

  def initialize(url, output_file)
    @url = url
    @output_file = output_file
    @command = `ffmpeg -y -ss 00:00:30 -t 00:0:10 -i #{@url} -c copy #{@output_file}`
  end

  def capture
    Rails.logger.info "Caputing stream command #{@command}"
    Open3.popen3(*command) do |_stdin, stdout, stderr, _wait_thr|
      Rails.logger.info "Output: #{stdout}"
      Rails.logger.info "Error: #{stderr}"
    end
  end

  def delete_file
    File.delete(@output_file) if File.exist?(@output_file)
  end
end
