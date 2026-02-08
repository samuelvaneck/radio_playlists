# frozen_string_literal: true

class AudioStream::M3u8 < AudioStream
  def initialize(url, output_file)
    super
    @command = ['ffmpeg', '-y', '-t', '00:00:05', '-i', @url, '-codec:a', 'libmp3lame', @output_file.to_s]
  end
end
