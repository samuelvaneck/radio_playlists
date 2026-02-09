# frozen_string_literal: true

class PersistentStream::Process
  SEGMENT_TIME = 10
  SEGMENT_WRAP = 3
  KILL_TIMEOUT = 5

  attr_reader :radio_station, :pid

  def initialize(radio_station)
    @radio_station = radio_station
    @pid = nil
  end

  def start
    FileUtils.mkdir_p(segment_directory)
    @pid = ::Process.spawn(*ffmpeg_command, out: ::File::NULL, err: log_file_path.to_s)
    ::Process.detach(@pid)
    Rails.logger.info "PersistentStream started for #{radio_station.name} (PID: #{@pid})"
    @pid
  end

  def stop
    return unless @pid

    ::Process.kill('TERM', @pid)
    wait_for_exit
  rescue Errno::ESRCH
    # Process already gone
  ensure
    @pid = nil
  end

  def alive?
    return false unless @pid

    ::Process.kill(0, @pid)
    true
  rescue Errno::ESRCH, Errno::EPERM
    false
  end

  def restart
    stop
    start
  end

  def segment_directory
    PersistentStream::SEGMENT_DIRECTORY.join(radio_station.audio_file_name)
  end

  def segment_list_path
    segment_directory.join('segments.csv')
  end

  private

  def ffmpeg_command
    cmd = ['ffmpeg', '-y']
    cmd += reconnect_options
    cmd += ['-i', radio_station.direct_stream_url]
    cmd += codec_options
    cmd += segment_options
    cmd << segment_pattern.to_s
    cmd
  end

  def reconnect_options
    ['-reconnect', '1', '-reconnect_streamed', '1', '-reconnect_delay_max', '30']
  end

  def codec_options
    if m3u8_stream?
      ['-codec:a', 'libmp3lame']
    else
      ['-c', 'copy']
    end
  end

  def segment_options
    [
      '-f', 'segment',
      '-segment_time', SEGMENT_TIME.to_s,
      '-segment_wrap', SEGMENT_WRAP.to_s,
      '-segment_list', segment_list_path.to_s,
      '-segment_list_type', 'csv',
      '-reset_timestamps', '1'
    ]
  end

  def segment_pattern
    segment_directory.join('segment%03d.mp3')
  end

  def m3u8_stream?
    radio_station.direct_stream_url.match?(/m3u8/i)
  end

  def log_file_path
    segment_directory.join('ffmpeg.log')
  end

  def wait_for_exit
    deadline = ::Process.clock_gettime(::Process::CLOCK_MONOTONIC) + KILL_TIMEOUT
    loop do
      ::Process.kill(0, @pid)
      break if ::Process.clock_gettime(::Process::CLOCK_MONOTONIC) >= deadline

      sleep 0.1
    end
    ::Process.kill('KILL', @pid)
  rescue Errno::ESRCH
    # Process exited
  end
end
