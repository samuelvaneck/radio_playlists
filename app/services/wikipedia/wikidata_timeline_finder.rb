# frozen_string_literal: true

module Wikipedia
  class WikidataTimelineFinder
    SPARQL_URL = 'https://query.wikidata.org/sparql'
    ENTITY_API_URL = 'https://www.wikidata.org'
    DEFAULT_LANGUAGE = 'en'

    DATE_CLAIM_PROPERTIES = {
      'P569' => { category: 'birth', title_template: 'Birth' },
      'P570' => { category: 'death', title_template: 'Death' },
      'P571' => { category: 'formation', title_template: 'Formation' },
      'P576' => { category: 'dissolution', title_template: 'Dissolution' }
    }.freeze

    def initialize(language: DEFAULT_LANGUAGE)
      @language = language
    end

    def call(wikibase_item)
      return [] if wikibase_item.blank?

      sparql_events(wikibase_item).presence || entity_api_events(wikibase_item)
    end

    private

    attr_reader :language

    def sparql_events(wikibase_item)
      rows = execute_query(timeline_query(wikibase_item))
      return [] if rows.blank?

      rows.filter_map { |row| build_event(row) }
    end

    def entity_api_events(wikibase_item)
      entity = fetch_entity(wikibase_item)
      return [] if entity.blank?

      DATE_CLAIM_PROPERTIES.filter_map do |property_id, meta|
        date = extract_date_claim(entity, property_id)
        next nil if date.blank?

        { 'category' => meta[:category], 'date' => date, 'title' => meta[:title_template], 'source' => 'wikidata' }
      end
    end

    def fetch_entity(wikibase_item)
      Rails.cache.fetch("wikidata:timeline_entity:#{language}:#{wikibase_item}", expires_in: 24.hours) do
        response = entity_connection.get('/w/api.php') do |req|
          req.params = { action: 'wbgetentities', ids: wikibase_item, format: 'json', props: 'claims', languages: language }
        end
        response.body&.dig('entities', wikibase_item)
      end
    rescue StandardError => e
      ExceptionNotifier.notify(e)
      Rails.logger.error("Wikidata entity API error: #{e.message}")
      nil
    end

    def extract_date_claim(entity, property_id)
      claim = entity.dig('claims', property_id)&.first
      time_value = claim&.dig('mainsnak', 'datavalue', 'value', 'time')
      return nil if time_value.blank?

      parse_date(time_value)
    end

    def entity_connection
      @entity_connection ||= Faraday.new(url: ENTITY_API_URL) do |conn|
        conn.response :json
        conn.headers['User-Agent'] = 'Airplays/1.0 (https://airplays.nl)'
      end
    end

    def timeline_query(wikibase_item)
      <<~SPARQL
        SELECT ?category ?date ?subject ?subjectLabel WHERE {
          {
            wd:#{wikibase_item} wdt:P569 ?date.
            BIND("birth" AS ?category)
            BIND(wd:#{wikibase_item} AS ?subject)
          } UNION {
            wd:#{wikibase_item} wdt:P570 ?date.
            BIND("death" AS ?category)
            BIND(wd:#{wikibase_item} AS ?subject)
          } UNION {
            wd:#{wikibase_item} wdt:P571 ?date.
            BIND("formation" AS ?category)
            BIND(wd:#{wikibase_item} AS ?subject)
          } UNION {
            wd:#{wikibase_item} wdt:P576 ?date.
            BIND("dissolution" AS ?category)
            BIND(wd:#{wikibase_item} AS ?subject)
          } UNION {
            wd:#{wikibase_item} p:P800 ?statement.
            ?statement ps:P800 ?subject.
            OPTIONAL { ?subject wdt:P577 ?date. }
            BIND("notable_work" AS ?category)
          } UNION {
            wd:#{wikibase_item} p:P166 ?statement.
            ?statement ps:P166 ?subject.
            OPTIONAL { ?statement pq:P585 ?date. }
            BIND("award" AS ?category)
          }
          SERVICE wikibase:label { bd:serviceParam wikibase:language "#{language}". }
        }
        ORDER BY ?date
      SPARQL
    end

    def execute_query(query)
      Rails.cache.fetch(cache_key(query), expires_in: 24.hours) do
        response = connection.get do |req|
          req.params['query'] = query
          req.params['format'] = 'json'
        end
        response.body&.dig('results', 'bindings') || []
      end
    rescue StandardError => e
      ExceptionNotifier.notify(e)
      Rails.logger.error("Wikidata timeline SPARQL error: #{e.message}")
      []
    end

    def build_event(row)
      category = row.dig('category', 'value')
      return nil if category.blank?

      {
        'category' => category,
        'date' => parse_date(row.dig('date', 'value').to_s),
        'title' => row.dig('subjectLabel', 'value').presence || category.humanize,
        'source' => 'wikidata'
      }
    end

    def parse_date(time_string)
      match = time_string.match(/([+-]?\d+)-(\d{2})-(\d{2})/)
      return nil unless match

      year = match[1].to_i
      return year.to_s if match[2].to_i.zero? || match[3].to_i.zero?

      format('%<year>04d-%<month>02d-%<day>02d', year: year.abs, month: match[2].to_i, day: match[3].to_i)
    end

    def cache_key(query)
      "wikidata:timeline:#{language}:#{Digest::MD5.hexdigest(query)}"
    end

    def connection
      @connection ||= Faraday.new(url: SPARQL_URL) do |conn|
        conn.response :json
        conn.headers['Accept'] = 'application/sparql-results+json'
        conn.headers['User-Agent'] = 'Airplays/1.0 (https://airplays.nl)'
      end
    end
  end
end
