# frozen_string_literal: true

class AudioStream::Mp3 < AudioStream
  def initialize(url, output_file, metadata_file)
    super
    # @command = "ffmpeg -y -ss 00:00:30 -t 00:00:10 -i #{@url} -c copy #{@output_file}"
    # ruby ffmppeg command as an array for Open3.popen3 escaping with shellwords
    @command = ["ffmpeg -y -ss 00:00:30 -t 00:00:10 -i #{@url} -c copy #{@output_file} -f ffmetadata #{@metadata_file}"]
  end
end
