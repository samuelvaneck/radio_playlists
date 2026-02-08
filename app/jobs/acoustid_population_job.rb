# frozen_string_literal: true

# AcoustidPopulationJob downloads YouTube audio, generates fingerprints,
# and submits them to the AcoustID database to improve recognition rates
# for Dutch radio songs.
#
# Usage:
#   AcoustidPopulationJob.perform_async(song_id)
#
# Requirements:
#   - Song must have id_on_youtube
#   - yt-dlp must be installed
#   - fpcalc must be installed
#   - ACOUSTID_API_KEY and ACOUSTID_USER_KEY environment variables
#
class AcoustidPopulationJob
  include Sidekiq::Job

  sidekiq_options queue: 'low', retry: 3

  # Enqueue jobs for all songs with YouTube IDs that haven't been submitted yet
  def self.enqueue_all(limit: nil)
    scope = Song.where(acoustid_submitted_at: nil)
              .where.not(id_on_youtube: nil)
    scope = scope.limit(limit) if limit

    count = 0
    scope.find_each do |song|
      perform_async(song.id)
      count += 1
    end

    Rails.logger.info "AcoustidPopulationJob: Enqueued #{count} songs for processing"
    count
  end

  def perform(song_id)
    @song = Song.find_by(id: song_id)
    return if @song.blank?
    return if @song.id_on_youtube.blank?
    return if @song.acoustid_submitted_at.present?

    Rails.logger.info "AcoustidPopulationJob: Processing song #{@song.id} (#{@song.title})"

    downloader = nil
    begin
      # Step 1: Download audio from YouTube
      downloader = YoutubeAudioDownloader.new(@song.id_on_youtube)
      download_result = downloader.download
      audio_file_path = download_result[:output_file]

      # Step 2: Find MusicBrainz recording ID (optional but recommended)
      musicbrainz_id = find_musicbrainz_recording_id

      # Step 3: Submit fingerprint to AcoustID
      submitter = AcoustidSubmitter.new(
        audio_file_path: audio_file_path,
        musicbrainz_id: musicbrainz_id,
        song: @song
      )
      submitter.submit

      # Step 4: Mark song as submitted
      @song.update!(acoustid_submitted_at: Time.current)

      Rails.logger.info "AcoustidPopulationJob: Successfully submitted song #{@song.id}"
    rescue YoutubeAudioDownloader::DownloadError => e
      Rails.logger.warn "AcoustidPopulationJob: YouTube download failed for song #{@song.id}: #{e.message}"
      raise # Retry via Sidekiq
    rescue AcoustidSubmitter::SubmissionError => e
      Rails.logger.error "AcoustidPopulationJob: AcoustID submission failed for song #{@song.id}: #{e.message}"
      raise # Retry via Sidekiq
    ensure
      downloader&.cleanup
    end
  end

  private

  def find_musicbrainz_recording_id
    finder = MusicBrainz::RecordingFinder.new(@song)
    finder.find_recording_id
  rescue StandardError => e
    Rails.logger.warn "AcoustidPopulationJob: MusicBrainz lookup failed for song #{@song.id}: #{e.message}"
    nil # Continue without MusicBrainz ID
  end
end
