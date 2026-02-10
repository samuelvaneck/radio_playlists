# frozen_string_literal: true

module MusicBrainz
  class RecordingFinder
    class ApiError < StandardError; end

    ENDPOINT = 'https://musicbrainz.org/ws/2/recording'
    USER_AGENT = 'Airwave/1.0.0 (https://airwaveapp.nl)'
    RATE_LIMIT_DELAY = 1.0 # MusicBrainz requires max 1 request/second

    attr_reader :recording_id, :title, :artist_name

    def initialize(song)
      @song = song
      @recording_id = nil
      @title = nil
      @artist_name = nil
    end

    def find_recording_id
      find_by_isrc || find_by_title_and_artist
      @recording_id
    end

    private

    def find_by_isrc
      return nil if @song.isrc.blank?

      Rails.logger.info "MusicBrainz::RecordingFinder: Searching by ISRC #{@song.isrc}"
      query = "isrc:#{@song.isrc}"
      search(query)
    end

    def find_by_title_and_artist
      return nil if @song.title.blank?

      artist_name = @song.artists.first&.name
      Rails.logger.info "MusicBrainz::RecordingFinder: Searching by title/artist: #{@song.title} - #{artist_name}"

      query = build_title_artist_query(@song.title, artist_name)
      search(query)
    end

    def build_title_artist_query(title, artist_name)
      parts = []
      parts << "recording:#{escape_query(title)}" if title.present?
      parts << "artist:#{escape_query(artist_name)}" if artist_name.present?
      parts.join(' AND ')
    end

    def escape_query(value)
      # Escape special Lucene characters and wrap in quotes for phrase matching
      escaped = value.gsub(%r{([+\-&|!(){}\[\]^"~*?:\\/])}, '\\\\\1')
      "\"#{escaped}\""
    end

    def search(query)
      sleep(RATE_LIMIT_DELAY) # Respect MusicBrainz rate limit

      uri = URI(ENDPOINT)
      uri.query = URI.encode_www_form(query: query, fmt: 'json', limit: 1)

      response = make_request(uri)
      handle_response(response)
    rescue StandardError => e
      Rails.logger.error "MusicBrainz::RecordingFinder error: #{e.message}"
      false
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

    def handle_response(response)
      unless response.is_a?(Net::HTTPSuccess)
        Rails.logger.warn "MusicBrainz::RecordingFinder: API returned #{response.code}"
        return false
      end

      data = JSON.parse(response.body)
      recordings = data['recordings']

      return false if recordings.blank?

      recording = recordings.first
      @recording_id = recording['id']
      @title = recording['title']
      @artist_name = extract_artist_name(recording)

      Rails.logger.info "MusicBrainz::RecordingFinder: Found recording #{@recording_id}"
      true
    rescue JSON::ParserError => e
      Rails.logger.error "MusicBrainz::RecordingFinder: Invalid JSON response: #{e.message}"
      false
    end

    def extract_artist_name(recording)
      artist_credits = recording['artist-credit']
      return nil if artist_credits.blank?

      artist_credits.map { |credit| credit['name'] }.join(', ')
    end
  end
end
