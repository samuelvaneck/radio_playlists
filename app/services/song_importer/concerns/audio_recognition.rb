# frozen_string_literal: true

module SongImporter::Concerns
  module AudioRecognition
    extend ActiveSupport::Concern

    private

    def recognize_song
      output_file = @radio_station.audio_file_path
      audio_stream = AudioStream::PersistentSegment.new(@radio_station, output_file)
      audio_stream.capture

      songrec = SongRecognizer.new(@radio_station, audio_stream:, skip_cleanup: true)
      songrec_result = songrec.recognized?
      @import_logger.log_recognition(songrec) if songrec_result

      acoustid = AcoustidRecognizer.new(output_file)
      acoustid.recognized?
      @import_logger.log_acoustid(acoustid)

      songrec_result ? songrec : nil
    rescue PersistentStream::SegmentReader::NoSegmentError,
           PersistentStream::SegmentReader::StaleSegmentError
      nil
    ensure
      audio_stream&.delete_file
    end
  end
end
