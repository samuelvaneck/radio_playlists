# frozen_string_literal: true

class AudioStream::Mp3 < AudioStream
  def initialize(url, output_file)
    super
    @command = ["ffmpeg -y -ss 00:00:30 -t 00:00:10 -i #{url} -c copy #{output_file}"]
  end
end
