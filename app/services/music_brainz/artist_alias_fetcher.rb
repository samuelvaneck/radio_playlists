# frozen_string_literal: true

module MusicBrainz
  class ArtistAliasFetcher
    SEARCH_ENDPOINT = 'https://musicbrainz.org/ws/2/artist'
    LOOKUP_ENDPOINT = 'https://musicbrainz.org/ws/2/artist'
    USER_AGENT = 'Airplays/1.0.0 (https://airplays.nl)'
    RATE_LIMIT_DELAY = 1.0
    SEARCH_SCORE_THRESHOLD = 90
    NAME_SIMILARITY_THRESHOLD = 90
    USEFUL_ALIAS_TYPES = ['Artist name', 'Legal name', 'Search hint'].freeze
    KEPT_LOCALES = [nil, 'en'].freeze

    def initialize(artist)
      @artist = artist
    end

    def call
      mbid = @artist.id_on_musicbrainz.presence || lookup_mbid
      return false if mbid.blank?

      data = fetch_artist(mbid)
      return false if data.blank?

      names = collected_names(data)
      names.concat(rename_target_names(data))

      @artist.update!(
        id_on_musicbrainz: mbid,
        aka_names: names.uniq.compact_blank,
        aka_names_checked_at: Time.current
      )
      true
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
      Rails.logger.error "MusicBrainz::ArtistAliasFetcher: Invalid JSON in search: #{e.message}"
      nil
    rescue StandardError => e
      Rails.logger.error "MusicBrainz::ArtistAliasFetcher: Search error: #{e.message}"
      nil
    end

    def name_matches?(candidate_name)
      score = (JaroWinkler.similarity(candidate_name.to_s.downcase, @artist.name.to_s.downcase) * 100).to_i
      score >= NAME_SIMILARITY_THRESHOLD
    end

    def fetch_artist(mbid)
      sleep(RATE_LIMIT_DELAY)
      uri = URI("#{LOOKUP_ENDPOINT}/#{mbid}")
      uri.query = URI.encode_www_form(inc: 'aliases artist-rels', fmt: 'json')

      response = make_request(uri)
      return nil unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    rescue JSON::ParserError => e
      Rails.logger.error "MusicBrainz::ArtistAliasFetcher: Invalid JSON in lookup: #{e.message}"
      nil
    rescue StandardError => e
      Rails.logger.error "MusicBrainz::ArtistAliasFetcher: Lookup error: #{e.message}"
      nil
    end

    def collected_names(data)
      names = data['aliases'].to_a.filter_map { |alias_entry| keep_alias?(alias_entry) ? alias_entry['name'] : nil }
      names << data['name'] if data['name'].present?
      names
    end

    def keep_alias?(alias_entry)
      return false if alias_entry['type'].blank?
      return false unless USEFUL_ALIAS_TYPES.include?(alias_entry['type'])

      KEPT_LOCALES.include?(alias_entry['locale'])
    end

    def rename_target_names(data)
      data['relations'].to_a.filter_map do |relation|
        next unless relation['type'] == 'artist rename'

        related_id = relation.dig('artist', 'id')
        next if related_id.blank?

        related_data = fetch_artist(related_id)
        next if related_data.blank?

        collected_names(related_data)
      end.flatten
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
