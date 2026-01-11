# frozen_string_literal: true

# AcoustidRecognizer uses Chromaprint (fpcalc) and AcoustID API to identify songs from audio files.
#
# == AcoustID Response Structure
#
# The full response is stored in SongImportLog#acoustid_raw_response for debugging.
# Below is a reference of available fields in the AcoustID response:
#
# === Currently Extracted Fields
#   results[0].score              → score (confidence 0-1)
#   results[0].recordings[0].id   → recording_id (MusicBrainz recording ID)
#   results[0].recordings[0].title → title (song title)
#   results[0].recordings[0].artists[0].name → artist_name
#
# === Example Response Structure
#   {
#     "status": "ok",
#     "results": [
#       {
#         "id": "acoustid-uuid",
#         "score": 0.987654,
#         "recordings": [
#           {
#             "id": "musicbrainz-recording-id",
#             "title": "Song Title",
#             "artists": [{ "id": "artist-id", "name": "Artist Name" }],
#             "releasegroups": [{ "title": "Album", "type": "Album" }]
#           }
#         ]
#       }
#     ]
#   }
#
class AcoustidRecognizer
  class RecognitionError < StandardError; end
  class FingerprintError < RecognitionError; end
  class ApiError < RecognitionError; end

  ACOUSTID_API_URL = 'https://api.acoustid.org/v2/lookup'
  MINIMUM_SCORE = 0.5

  attr_reader :result, :title, :artist_name, :recording_id, :score

  def initialize(audio_file_path)
    @audio_file_path = audio_file_path
    @api_key = ENV.fetch('ACOUSTID_API_KEY', nil)
  end

  def recognized?
    return false if @api_key.blank?
    return false unless File.exist?(@audio_file_path)

    fingerprint_data = generate_fingerprint
    return false unless fingerprint_data

    response = lookup_fingerprint(fingerprint_data)
    handle_response(response)
  rescue FingerprintError => e
    Rails.logger.warn "AcoustidRecognizer fingerprint failed: #{e.message}"
    false
  rescue ApiError => e
    Rails.logger.error "AcoustidRecognizer API error: #{e.message}"
    false
  rescue StandardError => e
    Rails.logger.error "AcoustidRecognizer unexpected error: #{e.class} - #{e.message}"
    false
  end

  private

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

  def lookup_fingerprint(fingerprint_data)
    uri = URI(ACOUSTID_API_URL)
    params = {
      client: @api_key,
      meta: 'recordings',
      fingerprint: fingerprint_data[:fingerprint],
      duration: fingerprint_data[:duration]
    }
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)

    raise ApiError, "AcoustID API returned #{response.code}: #{response.body.truncate(200)}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  rescue JSON::ParserError => e
    raise ApiError, "Invalid API response: #{e.message}"
  rescue StandardError => e
    raise ApiError, "API request failed: #{e.message}"
  end

  def handle_response(response)
    @result = response.with_indifferent_access

    if @result[:status] != 'ok'
      Rails.logger.warn "AcoustID returned status: #{@result[:status]} - #{@result[:error]}"
      return false
    end

    best_result = @result[:results]&.first
    return false unless best_result

    @score = best_result[:score].to_f
    return false if @score < MINIMUM_SCORE

    recording = best_result[:recordings]&.first
    return false unless recording

    @recording_id = recording[:id]
    @title = recording[:title]
    @artist_name = extract_artist_name(recording)

    @title.present? && @artist_name.present?
  end

  def extract_artist_name(recording)
    artists = recording[:artists]
    return nil if artists.blank?

    artists.map { |a| a[:name] }.join(', ')
  end
end
