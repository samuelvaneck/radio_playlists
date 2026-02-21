# frozen_string_literal: true

module MusicBrainz
  class IsrcsFinder
    ISRC_ENDPOINT = 'https://musicbrainz.org/ws/2/isrc'
    RECORDING_ENDPOINT = 'https://musicbrainz.org/ws/2/recording'
    USER_AGENT = 'RadioPlaylists/1.0.0 (https://playlists.samuelvaneck.com)'
    RATE_LIMIT_DELAY = 1.0

    def initialize(isrc)
      @isrc = isrc
    end

    def find
      return [] if @isrc.blank?

      recording_id = find_recording_id
      return [] if recording_id.blank?

      sleep(RATE_LIMIT_DELAY)
      fetch_isrcs(recording_id)
    end

    private

    def find_recording_id
      sleep(RATE_LIMIT_DELAY)

      uri = URI("#{ISRC_ENDPOINT}/#{@isrc}")
      uri.query = URI.encode_www_form(fmt: 'json')

      response = make_request(uri)
      return nil unless response.is_a?(Net::HTTPSuccess)

      data = JSON.parse(response.body)
      recordings = data['recordings']
      return nil if recordings.blank?

      recordings.first['id']
    rescue JSON::ParserError => e
      Rails.logger.error "MusicBrainz::IsrcsFinder: Invalid JSON response: #{e.message}"
      nil
    rescue StandardError => e
      Rails.logger.error "MusicBrainz::IsrcsFinder error finding recording: #{e.message}"
      nil
    end

    def fetch_isrcs(recording_id)
      uri = URI("#{RECORDING_ENDPOINT}/#{recording_id}")
      uri.query = URI.encode_www_form(inc: 'isrcs', fmt: 'json')

      response = make_request(uri)
      return [] unless response.is_a?(Net::HTTPSuccess)

      data = JSON.parse(response.body)
      isrcs = data['isrcs']
      return [] if isrcs.blank?

      Rails.logger.info "MusicBrainz::IsrcsFinder: Found #{isrcs.size} ISRCs for recording #{recording_id}"
      isrcs
    rescue JSON::ParserError => e
      Rails.logger.error "MusicBrainz::IsrcsFinder: Invalid JSON response: #{e.message}"
      []
    rescue StandardError => e
      Rails.logger.error "MusicBrainz::IsrcsFinder error fetching ISRCs: #{e.message}"
      []
    end

    def make_request(uri)
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      https.open_timeout = 10
      https.read_timeout = 10

      request = Net::HTTP::Get.new(uri)
      request['User-Agent'] = USER_AGENT
      request['Accept'] = 'application/json'

      https.request(request)
    end
  end
end
