# frozen_string_literal: true

class PersistentStream::SegmentReader
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
    latest_segment_path.present? && latest_segment_path.exist?
  end

  private

  def latest_segment_path
    @latest_segment_path ||= find_latest_segment
  end

  def find_latest_segment
    path = Rails.cache.read("persistent_streams:#{radio_station.audio_file_name}")
    path ? Pathname.new(path) : nil
  end
end
