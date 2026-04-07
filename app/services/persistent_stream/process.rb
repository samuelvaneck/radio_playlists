# frozen_string_literal: true

class PersistentStream::Process
  SEGMENT_TIME = 10
  SEGMENT_WRAP = 3
  SEGMENT_LIST_SIZE = 3
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

  private

  def ffmpeg_command
    cmd = ['ffmpeg', '-y', '-nostdin', '-loglevel', 'warning']
    cmd += reconnect_options
    cmd += ['-i', radio_station.direct_stream_url]
    cmd += ['-vn']
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
      ['-codec:a', 'libmp3lame', '-b:a', '64k', '-ar', '16000', '-ac', '1']
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
      '-segment_list_size', SEGMENT_LIST_SIZE.to_s,
      '-reset_timestamps', '1'
    ]
  end

  def segment_pattern
    segment_directory.join('segment%03d.mp3')
  end

  def m3u8_stream?
    radio_station.direct_stream_url.match?(/m3u8/i)
  end

  def segment_list_path
    segment_directory.join('segments.csv')
  end

  def log_file_path
    segment_directory.join('ffmpeg.log')
  end

  def wait_for_exit
    Timeout.timeout(KILL_TIMEOUT) do
      sleep 0.5 until process_exited?
    end
  rescue Timeout::Error
    ::Process.kill('KILL', @pid)
  rescue Errno::ESRCH
    # Process exited
  end

  def process_exited?
    ::Process.kill(0, @pid)
    false
  rescue Errno::ESRCH
    true
  end
end
