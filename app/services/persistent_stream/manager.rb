# frozen_string_literal: true

class PersistentStream::Manager
  HEALTH_CHECK_INTERVAL = 30
  SEGMENT_TRACK_INTERVAL = 5
  STALE_THRESHOLD = 30

  attr_reader :processes

  def initialize
    @processes = {}
    @running = false
  end

  def start
    @running = true
    setup_signal_handlers
    start_all_processes
    monitor_loop
  ensure
    stop_all_processes
  end

  def stop
    @running = false
  end

  def status
    processes.map do |station_id, process|
      station = process.radio_station
      state = if process.alive?
                reader = PersistentStream::SegmentReader.new(station)
                reader.available? ? 'ACTIVE' : 'STALE'
              else
                'NOT RUNNING'
              end

      { id: station_id, name: station.name, state: state, pid: process.pid }
    end
  end

  private

  def start_all_processes
    stations_with_direct_stream.find_each do |station|
      start_process(station)
    end
    Rails.logger.info "PersistentStream::Manager started #{processes.size} processes"
  end

  def stop_all_processes
    processes.each_value(&:stop)
    processes.clear
    Rails.logger.info 'PersistentStream::Manager stopped all processes'
  end

  def start_process(station)
    process = PersistentStream::Process.new(station)
    process.start
    @processes[station.id] = process
  rescue StandardError => e
    Rails.logger.error "Failed to start persistent stream for #{station.name}: #{e.message}"
  end

  def monitor_loop
    last_health_check = Time.current
    while @running
      sleep SEGMENT_TRACK_INTERVAL
      track_segments
      if Time.current - last_health_check >= HEALTH_CHECK_INTERVAL
        check_health
        last_health_check = Time.current
      end
    end
  end

  def track_segments
    processes.each_value do |process|
      next unless process.alive?

      latest = find_latest_completed_segment(process.segment_directory)
      next unless latest

      cache_key = "persistent_streams:#{process.radio_station.audio_file_name}"
      Rails.cache.write(cache_key, latest.to_s, expires_in: STALE_THRESHOLD.seconds)
    end
  end

  def find_latest_completed_segment(directory)
    segments = Dir.glob(directory.join('segment*.mp3')).sort_by { |f| File.mtime(f) }
    return nil if segments.size < 2

    Pathname.new(segments[-2])
  end

  def check_health
    processes.each do |station_id, process|
      next if process.alive?

      Rails.logger.warn "PersistentStream for #{process.radio_station.name} (#{station_id}) died, restarting..."
      process.restart
    rescue StandardError => e
      Rails.logger.error "Failed to restart persistent stream for station #{station_id}: #{e.message}"
    end
  end

  def setup_signal_handlers
    %w[TERM INT].each do |signal|
      trap(signal) { stop }
    end
  end

  def stations_with_direct_stream
    RadioStation.unscoped.where.not(direct_stream_url: [nil, ''])
  end
end
