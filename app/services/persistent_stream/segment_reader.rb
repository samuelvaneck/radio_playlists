# frozen_string_literal: true

class PersistentStream::SegmentReader
  STALE_THRESHOLD = 30

  NoSegmentError = Class.new(StandardError)
  StaleSegmentError = Class.new(StandardError)

  attr_reader :radio_station

  def initialize(radio_station)
    @radio_station = radio_station
  end

  def read_latest(output_file)
    raise NoSegmentError, "No segments available for #{radio_station.name}" unless available?

    FileUtils.cp(latest_segment_path, output_file)
    output_file
  end

  def available?
    return false unless segment_list_path.exist?
    return false unless latest_segment_path

    fresh_segment?
  end

  private

  def segment_list_path
    segment_directory.join('segments.csv')
  end

  def segment_directory
    PersistentStream::SEGMENT_DIRECTORY.join(radio_station.audio_file_name)
  end

  def latest_segment_path
    @latest_segment_path ||= find_latest_segment
  end

  def find_latest_segment
    return nil unless segment_list_path.exist?

    lines = File.readlines(segment_list_path).reject(&:blank?)
    return nil if lines.empty?

    last_entry = lines.last.strip.split(',').first
    return nil if last_entry.blank?

    path = if Pathname.new(last_entry).absolute?
             Pathname.new(last_entry)
           else
             segment_directory.join(last_entry)
           end

    path.exist? ? path : nil
  end

  def fresh_segment?
    return false unless latest_segment_path

    age = Time.current - File.mtime(latest_segment_path)
    age < STALE_THRESHOLD
  end
end
