# frozen_string_literal: true

module Wikipedia
  class UrlFinder < Base
    SIMILARITY_THRESHOLD = 92
    MUSICBRAINZ_HOST = 'https://musicbrainz.org'
    MUSICBRAINZ_USER_AGENT = 'Airplays/1.0.0 (https://airplays.nl)'
    MUSICBRAINZ_RATE_LIMIT_DELAY = 1.0

    def find_for_artist(artist)
      return nil if artist.blank?

      from_musicbrainz(artist.id_on_musicbrainz) || from_opensearch(artist.name, hint: 'musician')
    end

    def find_for_name(name, hint: nil)
      return nil if name.blank?

      from_opensearch(name, hint: hint)
    end

    private

    def from_musicbrainz(mbid)
      return nil if mbid.blank?

      data = fetch_musicbrainz_artist(mbid)
      relations = data.is_a?(Hash) ? data['relations'].to_a : []
      wiki_relations = relations.select { |rel| rel['type'] == 'wikipedia' && rel.dig('url', 'resource').present? }
      return nil if wiki_relations.empty?

      preferred = wiki_relations.find { |rel| rel.dig('url', 'resource').include?("//#{language}.wikipedia.org/") }
      (preferred || wiki_relations.first).dig('url', 'resource')
    end

    def from_opensearch(name, hint: nil)
      query = hint.present? ? "#{name} #{hint}" : name
      response = make_mediawiki_request(action: 'opensearch', search: query, limit: 1)
      return nil unless response.is_a?(Array)

      title = response[1]&.first
      url = response[3]&.first
      return nil if title.blank? || url.blank?
      return nil unless title_matches?(title, name)

      url
    end

    def title_matches?(title, name)
      cleaned = title.sub(/\s*\(.*?\)\s*\z/, '')
      score = (JaroWinkler.similarity(cleaned.downcase, name.to_s.downcase) * 100).to_i
      score >= SIMILARITY_THRESHOLD
    end

    def fetch_musicbrainz_artist(mbid)
      Rails.cache.fetch("wikipedia_url_finder:mb_artist:#{mbid}", expires_in: 24.hours) do
        sleep(MUSICBRAINZ_RATE_LIMIT_DELAY)
        response = musicbrainz_connection.get("/ws/2/artist/#{mbid}", { inc: 'url-rels', fmt: 'json' })
        response.success? ? response.body : nil
      end
    rescue StandardError => e
      ExceptionNotifier.notify(e)
      Rails.logger.error("Wikipedia::UrlFinder MusicBrainz error: #{e.message}")
      nil
    end

    def musicbrainz_connection
      @musicbrainz_connection ||= Faraday.new(url: MUSICBRAINZ_HOST) do |conn|
        conn.options.timeout = 10
        conn.options.open_timeout = 5
        conn.headers['User-Agent'] = MUSICBRAINZ_USER_AGENT
        conn.headers['Accept'] = 'application/json'
        conn.response :json
      end
    end
  end
end
