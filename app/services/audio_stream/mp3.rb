# frozen_string_literal: true

class AudioStream::Mp3 < AudioStream
  def initialize(url, output_file)
    super
    @command = ['ffmpeg', '-y', '-t', '00:00:05', '-i', url, '-c', 'copy', output_file.to_s]
  end
end
