# frozen_string_literal: true

class AudioStream::PersistentSegment < AudioStream
  def initialize(radio_station, output_file)
    super(radio_station.direct_stream_url, output_file)
    @radio_station = radio_station
    @segment_reader = PersistentStream::SegmentReader.new(radio_station)
  end

  def capture
    @segment_reader.read_latest(@output_file)
    Rails.logger.debug "PersistentSegment: copied segment for #{@radio_station.name} to #{@output_file}"
  rescue PersistentStream::SegmentReader::NoSegmentError, PersistentStream::SegmentReader::StaleSegmentError => e
    Rails.logger.error "PersistentSegment capture failed for #{@radio_station.name}: #{e.message}"
    raise
  end
end
