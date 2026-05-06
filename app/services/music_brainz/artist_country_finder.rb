# frozen_string_literal: true

module MusicBrainz
  class ArtistCountryFinder
    SEARCH_ENDPOINT = 'https://musicbrainz.org/ws/2/artist'
    LOOKUP_ENDPOINT = 'https://musicbrainz.org/ws/2/artist'
    USER_AGENT = 'Airplays/1.0.0 (https://airplays.nl)'
    RATE_LIMIT_DELAY = 1.0
    SEARCH_SCORE_THRESHOLD = 90
    NAME_SIMILARITY_THRESHOLD = 90

    def initialize(artist)
      @artist = artist
    end

    def call
      mbid = @artist.id_on_musicbrainz.presence || lookup_mbid
      return nil if mbid.blank?

      data = fetch_artist(mbid)
      return nil if data.blank?

      @artist.update(id_on_musicbrainz: mbid) if @artist.id_on_musicbrainz.blank?
      extract_country_code(data)
    end

    private

    def lookup_mbid
      data = search_by_name
      return nil if data.blank?

      candidate = data['artists']&.first
      return nil if candidate.blank?
      return nil if candidate['score'].to_i < SEARCH_SCORE_THRESHOLD
      return nil unless name_matches?(candidate['name'])

      candidate['id']
    end

    def search_by_name
      sleep(RATE_LIMIT_DELAY)
      uri = URI(SEARCH_ENDPOINT)
      uri.query = URI.encode_www_form(query: "artist:\"#{@artist.name}\"", fmt: 'json', limit: 1)

      response = make_request(uri)
      return nil unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    rescue JSON::ParserError => e
      Rails.logger.error "MusicBrainz::ArtistCountryFinder: Invalid JSON in search: #{e.message}"
      nil
    rescue StandardError => e
      Rails.logger.error "MusicBrainz::ArtistCountryFinder: Search error: #{e.message}"
      nil
    end

    def name_matches?(candidate_name)
      score = (JaroWinkler.similarity(candidate_name.to_s.downcase, @artist.name.to_s.downcase) * 100).to_i
      score >= NAME_SIMILARITY_THRESHOLD
    end

    def fetch_artist(mbid)
      sleep(RATE_LIMIT_DELAY)
      uri = URI("#{LOOKUP_ENDPOINT}/#{mbid}")
      uri.query = URI.encode_www_form(fmt: 'json')

      response = make_request(uri)
      return nil unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    rescue JSON::ParserError => e
      Rails.logger.error "MusicBrainz::ArtistCountryFinder: Invalid JSON in lookup: #{e.message}"
      nil
    rescue StandardError => e
      Rails.logger.error "MusicBrainz::ArtistCountryFinder: Lookup error: #{e.message}"
      nil
    end

    def extract_country_code(data)
      data['country'].presence || data.dig('area', 'iso-3166-1-codes')&.first
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
