# frozen_string_literal: true

class TrackScraper::YoursafeVideoProcessor < TrackScraper
  ARTIST_TITLE_SEPARATOR = ' - '
  OCR_LANGUAGES = 'eng+nld+deu+fra+spa+ita+por+rus+tur'

  def last_played_song
    frame_file = extract_video_frame
    return false unless frame_file

    text = ocr_frame(frame_file)
    return false if text.blank?

    artist_title_line = extract_artist_title_line(text)
    return false if artist_title_line.blank?

    @raw_response = { ocr_text: text, parsed_line: artist_title_line }
    @artist_name, @title = parse_artist_title(artist_title_line)
    return false if @artist_name.blank? || @title.blank?

    @title = TitleSanitizer.sanitize(@title)
    @broadcasted_at = Time.zone.now
    true
  rescue StandardError => e
    Rails.logger.warn("YoursafeVideoProcessor: #{e.message}")
    ExceptionNotifier.notify(e)
    false
  ensure
    File.delete(frame_file) if frame_file && File.exist?(frame_file)
  end

  private

  def extract_video_frame
    output_file = Rails.root.join("tmp/audio/yoursafe_frame_#{SecureRandom.hex(4)}.png").to_s
    _stdout, _stderr, status = Open3.capture3(
      'ffmpeg', '-y', '-t', '1',
      '-i', @radio_station.direct_stream_url,
      '-vframes', '1', '-update', '1',
      output_file
    )

    status.success? && File.exist?(output_file) ? output_file : nil
  end

  def ocr_frame(frame_file)
    image = RTesseract.new(frame_file, lang: OCR_LANGUAGES)
    image.to_s.strip
  end

  def extract_artist_title_line(text)
    lines = text.split("\n").map(&:strip).reject(&:blank?)
    lines.reverse_each do |line|
      return line if line.include?(ARTIST_TITLE_SEPARATOR) && !header_line?(line)
    end
    nil
  end

  def header_line?(line)
    line.match?(/je luistert naar|yoursafe/i)
  end

  def parse_artist_title(line)
    artist, title = line.split(ARTIST_TITLE_SEPARATOR, 2)
    [artist&.strip&.presence, title&.strip&.presence]
  end
end
