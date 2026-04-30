# frozen_string_literal: true

class TrackScraper::YoursafeVideoProcessor < TrackScraper
  ARTIST_TITLE_SEPARATOR = ' - '
  OCR_LANGUAGES = 'eng+nld+deu+fra+spa+ita+por+rus+tur'
  FFMPEG_TIMEOUT_SECONDS = 15
  OCR_TIMEOUT_SECONDS = 15
  FFMPEG_RW_TIMEOUT_MICROSECONDS = '5000000'

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
    status = run_ffmpeg(output_file)
    status&.success? && File.exist?(output_file) ? output_file : nil
  end

  # Wraps the ffmpeg invocation in popen3 with a wall-clock kill so a hanging
  # HLS read can't keep the Sidekiq worker thread occupied past ImportSongJob's
  # 60s lock TTL. -rw_timeout makes ffmpeg fail fast on its own when possible;
  # the kill is the safety net.
  def run_ffmpeg(output_file)
    cmd = [
      'ffmpeg', '-y',
      '-rw_timeout', FFMPEG_RW_TIMEOUT_MICROSECONDS,
      '-t', '1',
      '-i', @radio_station.direct_stream_url,
      '-vframes', '1', '-update', '1',
      output_file
    ]
    Open3.popen3(*cmd) do |stdin, _stdout, _stderr, wait_thr|
      stdin.close
      if wait_thr.join(FFMPEG_TIMEOUT_SECONDS)
        wait_thr.value
      else
        Process.kill('KILL', wait_thr.pid)
        wait_thr.join
        Rails.logger.warn("YoursafeVideoProcessor: ffmpeg timed out after #{FFMPEG_TIMEOUT_SECONDS}s")
        nil
      end
    end
  end

  def ocr_frame(frame_file)
    Timeout.timeout(OCR_TIMEOUT_SECONDS) do
      image = RTesseract.new(frame_file, lang: OCR_LANGUAGES)
      image.to_s.strip
    end
  rescue Timeout::Error
    Rails.logger.warn("YoursafeVideoProcessor: OCR timed out after #{OCR_TIMEOUT_SECONDS}s")
    ''
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
