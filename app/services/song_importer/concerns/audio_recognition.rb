# frozen_string_literal: true

module SongImporter::Concerns
  module AudioRecognition
    extend ActiveSupport::Concern

    private

    def recognize_song
      output_file = @radio_station.audio_file_path
      audio_stream = build_audio_stream(output_file)

      begin
        audio_stream.capture
      rescue PersistentStream::SegmentReader::NoSegmentError, PersistentStream::SegmentReader::StaleSegmentError => e
        Rails.logger.warn "Persistent segment unavailable for #{@radio_station.name}, falling back to Icecast: #{e.message}"
        audio_stream = build_icecast_stream(output_file)
        audio_stream.capture
      end

      songrec = SongRecognizer.new(@radio_station, audio_stream:, skip_cleanup: true)
      songrec_result = songrec.recognized?
      @import_logger.log_recognition(songrec) if songrec_result

      acoustid = AcoustidRecognizer.new(output_file)
      acoustid.recognized?
      @import_logger.log_acoustid(acoustid)

      songrec_result ? songrec : nil
    ensure
      audio_stream&.delete_file
    end

    def build_audio_stream(output_file)
      return AudioStream::PersistentSegment.new(@radio_station, output_file) if persistent_segment_available?

      build_icecast_stream(output_file)
    end

    def build_icecast_stream(output_file)
      extension = @radio_station.direct_stream_url.split(/\.|-/).last
      if extension.match?(/m3u8/)
        AudioStream::M3u8.new(@radio_station.direct_stream_url, output_file)
      else
        AudioStream::Mp3.new(@radio_station.direct_stream_url, output_file)
      end
    end

    def persistent_segment_available?
      @radio_station.direct_stream_url.present? && PersistentStream::SegmentReader.new(@radio_station).available?
    end
  end
end
