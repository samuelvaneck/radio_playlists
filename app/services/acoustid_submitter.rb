# frozen_string_literal: true

# AcoustidSubmitter submits audio fingerprints to the AcoustID database.
#
# This helps populate AcoustID with Dutch radio songs that may not be in MusicBrainz,
# improving future recognition rates.
#
# == AcoustID Submit API
#
# POST https://api.acoustid.org/v2/submit
#
# Required parameters:
#   client      - Application API key (ACOUSTID_API_KEY)
#   user        - Personal user API key (ACOUSTID_USER_KEY)
#   duration.0  - Audio duration in seconds
#   fingerprint.0 - Chromaprint fingerprint
#
# Optional but recommended:
#   mbid.0      - MusicBrainz recording ID (links fingerprint to metadata)
#   track.0     - Track title
#   artist.0    - Artist name
#
# Rate limit: max 3 requests/second
# Submissions are processed asynchronously by AcoustID
#
class AcoustidSubmitter
  class SubmissionError < StandardError; end
  class FingerprintError < SubmissionError; end
  class ApiError < SubmissionError; end

  SUBMIT_URL = 'https://api.acoustid.org/v2/submit'
  RATE_LIMIT_DELAY = 0.34 # ~3 requests/second max

  attr_reader :result, :submission_id

  def initialize(audio_file_path:, musicbrainz_id: nil, song: nil)
    @audio_file_path = audio_file_path
    @musicbrainz_id = musicbrainz_id
    @song = song
    @api_key = ENV.fetch('ACOUSTID_API_KEY', nil)
    @user_key = ENV.fetch('ACOUSTID_USER_KEY', nil)
  end

  def submit
    validate_configuration!
    validate_audio_file!

    fingerprint_data = generate_fingerprint
    response = submit_to_acoustid(fingerprint_data)
    handle_response(response)
  rescue FingerprintError => e
    Rails.logger.error "AcoustidSubmitter fingerprint failed: #{e.message}"
    raise
  rescue ApiError => e
    Rails.logger.error "AcoustidSubmitter API error: #{e.message}"
    raise
  end

  def submitted?
    @submission_id.present?
  end

  private

  def validate_configuration!
    raise SubmissionError, 'ACOUSTID_API_KEY is not configured' if @api_key.blank?
    raise SubmissionError, 'ACOUSTID_USER_KEY is not configured' if @user_key.blank?
  end

  def validate_audio_file!
    raise FingerprintError, 'Audio file path is required' if @audio_file_path.blank?
    raise FingerprintError, "Audio file not found: #{@audio_file_path}" unless File.exist?(@audio_file_path)
  end

  def generate_fingerprint
    command = "fpcalc -json #{Shellwords.escape(@audio_file_path)}"
    output, error, status = Open3.capture3(command)

    raise FingerprintError, "fpcalc failed: #{error.presence || 'unknown error'}" unless status.success?

    result = JSON.parse(output)
    {
      fingerprint: result['fingerprint'],
      duration: result['duration'].to_i
    }
  rescue JSON::ParserError => e
    raise FingerprintError, "Invalid fpcalc output: #{e.message}"
  end

  def submit_to_acoustid(fingerprint_data)
    sleep(RATE_LIMIT_DELAY) # Respect AcoustID rate limit

    uri = URI(SUBMIT_URL)
    params = build_submission_params(fingerprint_data)

    Rails.logger.info "AcoustidSubmitter: Submitting fingerprint (duration: #{fingerprint_data[:duration]}s)"

    response = Net::HTTP.post_form(uri, params)

    raise ApiError, "AcoustID API returned #{response.code}: #{response.body.truncate(200)}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  rescue JSON::ParserError => e
    raise ApiError, "Invalid API response: #{e.message}"
  rescue StandardError => e
    raise ApiError, "API request failed: #{e.class} - #{e.message}"
  end

  def build_submission_params(fingerprint_data)
    params = {
      'client' => @api_key,
      'user' => @user_key,
      'duration.0' => fingerprint_data[:duration].to_s,
      'fingerprint.0' => fingerprint_data[:fingerprint]
    }

    # Add MusicBrainz recording ID if available (links fingerprint to existing metadata)
    params['mbid.0'] = @musicbrainz_id if @musicbrainz_id.present?

    # Add optional metadata from song
    if @song.present?
      params['track.0'] = @song.title if @song.title.present?
      params['artist.0'] = @song.artists.first&.name if @song.artists.any?
    end

    params
  end

  def handle_response(response)
    @result = response.with_indifferent_access

    if @result[:status] != 'ok'
      error_message = @result[:error]&.dig(:message) || @result[:error] || 'Unknown error'
      raise ApiError, "AcoustID submission failed: #{error_message}"
    end

    submissions = @result[:submissions]
    if submissions.present?
      @submission_id = submissions.first[:id]
      Rails.logger.info "AcoustidSubmitter: Submission accepted (ID: #{@submission_id})"
    else
      Rails.logger.info 'AcoustidSubmitter: Submission accepted (no ID returned)'
    end

    true
  end
end
