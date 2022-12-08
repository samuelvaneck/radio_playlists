# frozen_string_literal: true

class AudioStreamFfmpeg
  attr_reader :command, :output_file, :url

  def initialize(url, output_file)
    @url = url
    @output_file = Rails.root.join(output_file)
    @command = `ffmpeg -y -ss 00:00:20 -to 00:01:20 -i #{@url} -c copy #{@output_file}`
  end

  def capture
    Open3.popen3(*command) do |_stdin, stdout, stderr, wait_thr|
      Rails.logger.info "Caputing stream command #{command}"
      Rails.logger.info "Output: #{stdout}"
      Rails.logger.info "Error: #{stderr}"
    end
  end
end
