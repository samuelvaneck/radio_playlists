# frozen_string_literal: true

module Wikipedia
  class WikidataFinder
    WIKIDATA_API_URL = 'https://www.wikidata.org'
    DEFAULT_LANGUAGE = 'en'

    # Wikidata property IDs for artist information
    PROPERTIES = {
      date_of_birth: 'P569',
      place_of_birth: 'P19',
      nationality: 'P27',
      member_of: 'P463',
      has_part: 'P527',
      genre: 'P136',
      occupation: 'P106',
      record_label: 'P264',
      official_website: 'P856',
      start_period: 'P2031',
      end_period: 'P2032',
      instrument: 'P1303',
      # Song-specific properties
      youtube_video_id: 'P1651',
      spotify_track_id: 'P2207',
      isrc: 'P1243',
      publication_date: 'P577',
      performer: 'P175'
    }.freeze

    WIKIDATA_SPARQL_URL = 'https://query.wikidata.org/sparql'

    def initialize(language: DEFAULT_LANGUAGE)
      @language = language
    end

    def get_general_info(wikibase_item)
      return nil if wikibase_item.blank?

      entity = fetch_entity_data(wikibase_item)
      return nil if entity.nil?

      extract_artist_info(entity)
    end

    def get_official_website(wikibase_item)
      return nil if wikibase_item.blank?

      entity = fetch_entity_data(wikibase_item)
      extract_claim_value(entity, :official_website)
    end

    def get_song_info(wikibase_item)
      return nil if wikibase_item.blank?

      entity = fetch_entity_data(wikibase_item)
      return nil if entity.nil?

      extract_song_info(entity)
    end

    def get_youtube_video_id(wikibase_item)
      return nil if wikibase_item.blank?

      entity = fetch_entity_data(wikibase_item)
      extract_claim_value(entity, :youtube_video_id)
    end

    def search_by_spotify_id(spotify_id)
      return nil if spotify_id.blank?

      execute_sparql_query(spotify_id_query(spotify_id))
    end

    def search_by_isrc(isrc)
      return nil if isrc.blank?

      execute_sparql_query(isrc_query(isrc))
    end

    private

    attr_reader :language

    def fetch_entity_data(wikibase_item)
      response = fetch_entity(wikibase_item)
      response&.dig('entities', wikibase_item)
    end

    def fetch_entity(wikibase_item)
      Rails.cache.fetch(cache_key(wikibase_item), expires_in: 24.hours) do
        response = connection.get('/w/api.php') do |req|
          req.params = {
            action: 'wbgetentities',
            ids: wikibase_item,
            format: 'json',
            props: 'claims|labels',
            languages: language
          }
        end
        response.body
      end
    rescue StandardError => e
      ExceptionNotifier.notify_new_relic(e)
      Rails.logger.error("Wikidata API error: #{e.message}")
      nil
    end

    def extract_artist_info(entity)
      {
        'date_of_birth' => extract_date_claim(entity, :date_of_birth),
        'place_of_birth' => extract_entity_label_claim(entity, :place_of_birth),
        'nationality' => extract_entity_labels_claim(entity, :nationality),
        'member_of' => extract_entity_labels_claim(entity, :member_of),
        'current_members' => extract_entity_labels_claim(entity, :has_part),
        'genres' => extract_entity_labels_claim(entity, :genre),
        'occupations' => extract_entity_labels_claim(entity, :occupation),
        'record_labels' => extract_entity_labels_claim(entity, :record_label),
        'instruments' => extract_entity_labels_claim(entity, :instrument),
        'official_website' => extract_claim_value(entity, :official_website),
        'active_years' => extract_active_years(entity)
      }.compact
    end

    def extract_claim_value(entity, property_key)
      property_id = PROPERTIES[property_key]
      claim = entity.dig('claims', property_id)&.first
      claim&.dig('mainsnak', 'datavalue', 'value')
    end

    def extract_date_claim(entity, property_key)
      property_id = PROPERTIES[property_key]
      claim = entity.dig('claims', property_id)&.first
      time_value = claim&.dig('mainsnak', 'datavalue', 'value', 'time')
      return nil if time_value.nil?

      parse_wikidata_date(time_value)
    end

    def extract_entity_label_claim(entity, property_key)
      property_id = PROPERTIES[property_key]
      claim = entity.dig('claims', property_id)&.first
      entity_id = claim&.dig('mainsnak', 'datavalue', 'value', 'id')
      return nil if entity_id.nil?

      fetch_entity_label(entity_id)
    end

    def extract_entity_labels_claim(entity, property_key)
      property_id = PROPERTIES[property_key]
      claims = entity.dig('claims', property_id)
      return nil if claims.blank?

      entity_ids = claims.filter_map { |claim| claim.dig('mainsnak', 'datavalue', 'value', 'id') }
      return nil if entity_ids.empty?

      fetch_entity_labels(entity_ids)
    end

    def extract_active_years(entity)
      start_year = extract_date_claim(entity, :start_period)
      end_year = extract_date_claim(entity, :end_period)
      return nil if start_year.nil? && end_year.nil?

      { 'start' => start_year, 'end' => end_year }
    end

    def fetch_entity_label(entity_id)
      fetch_entity_labels([entity_id])&.first
    end

    def fetch_entity_labels(entity_ids)
      return nil if entity_ids.empty?

      response = Rails.cache.fetch(cache_key("labels:#{entity_ids.join(',')}"), expires_in: 24.hours) do
        connection.get('/w/api.php') do |req|
          req.params = {
            action: 'wbgetentities',
            ids: entity_ids.join('|'),
            format: 'json',
            props: 'labels',
            languages: language
          }
        end.body
      end

      return nil if response.nil?

      entity_ids.filter_map do |entity_id|
        response.dig('entities', entity_id, 'labels', language, 'value')
      end
    rescue StandardError => e
      ExceptionNotifier.notify_new_relic(e)
      Rails.logger.error("Wikidata API error fetching labels: #{e.message}")
      nil
    end

    def parse_wikidata_date(time_string)
      match = time_string.match(/([+-]?\d+)-(\d{2})-(\d{2})/)
      return nil unless match

      year = match[1].to_i
      return year.to_s if match[2].to_i.zero? || match[3].to_i.zero?

      format('%<year>04d-%<month>02d-%<day>02d', year: year.abs, month: match[2].to_i, day: match[3].to_i)
    end

    def connection
      @connection ||= Faraday.new(url: WIKIDATA_API_URL) { |conn| conn.response :json }
    end

    def cache_key(identifier)
      "wikidata:#{language}:#{identifier}"
    end

    def extract_song_info(entity)
      {
        'youtube_video_id' => extract_claim_value(entity, :youtube_video_id),
        'publication_date' => extract_date_claim(entity, :publication_date),
        'genres' => extract_entity_labels_claim(entity, :genre),
        'performers' => extract_entity_labels_claim(entity, :performer),
        'record_labels' => extract_entity_labels_claim(entity, :record_label),
        'isrc' => extract_claim_value(entity, :isrc)
      }.compact
    end

    def execute_sparql_query(query)
      Rails.cache.fetch(cache_key("sparql:#{Digest::MD5.hexdigest(query)}"), expires_in: 24.hours) do
        response = sparql_connection.get do |req|
          req.params['query'] = query
          req.params['format'] = 'json'
        end
        extract_wikibase_item_from_sparql(response.body)
      end
    rescue StandardError => e
      ExceptionNotifier.notify_new_relic(e)
      Rails.logger.error("Wikidata SPARQL error: #{e.message}")
      nil
    end

    def extract_wikibase_item_from_sparql(response)
      return nil if response.blank?

      item_uri = response.dig('results', 'bindings', 0, 'item', 'value')
      return nil if item_uri.blank?

      item_uri.split('/').last
    end

    def spotify_id_query(spotify_id)
      <<~SPARQL
        SELECT ?item WHERE {
          ?item wdt:P2207 "#{spotify_id}".
        }
        LIMIT 1
      SPARQL
    end

    def isrc_query(isrc)
      <<~SPARQL
        SELECT ?item WHERE {
          ?item wdt:P1243 "#{isrc}".
        }
        LIMIT 1
      SPARQL
    end

    def sparql_connection
      @sparql_connection ||= Faraday.new(url: WIKIDATA_SPARQL_URL) do |conn|
        conn.response :json
        conn.headers['Accept'] = 'application/sparql-results+json'
        conn.headers['User-Agent'] = 'RadioPlaylists/1.0 (https://radioplaylists.nl)'
      end
    end
  end
end
