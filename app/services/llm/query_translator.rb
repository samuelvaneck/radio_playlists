# frozen_string_literal: true

module Llm
  class QueryTranslator < Base
    MOOD_MAPPINGS = {
      'upbeat' => { valence_min: 0.6, energy_min: 0.6 },
      'happy' => { valence_min: 0.6 },
      'sad' => { valence_max: 0.3 },
      'chill' => { energy_max: 0.4, valence_min: 0.3 },
      'energetic' => { energy_min: 0.7 },
      'acoustic' => { acousticness_min: 0.7 },
      'danceable' => { danceability_min: 0.7 },
      'calm' => { energy_max: 0.3 },
      'intense' => { energy_min: 0.8, loudness_min: -8.0 },
      'mellow' => { energy_max: 0.4, acousticness_min: 0.4 },
      'party' => { danceability_min: 0.7, energy_min: 0.7 }
    }.freeze

    SORT_OPTIONS = %w[most_played newest popularity].freeze
    SEARCH_TYPES = %w[songs artists].freeze
    STRING_FILTERS = %w[text_search artist title album genre radio_station period lyrics].freeze
    MAX_STRING_LENGTH = 200
    COUNTRY_CODE_PATTERN = /\A[A-Z]{2,3}\z/

    def initialize(query)
      super()
      @query = query
    end

    def translate
      response = chat(system_prompt: system_prompt, user_message: @query)
      return {} if response.blank?

      parse_response(response)
    end

    private

    def system_prompt
      <<~PROMPT
        You are a search query translator for a Dutch radio airplay tracking application.
        Translate the user's natural language query into a JSON object with search filters.

        Available filters:
        - "search_type": "songs" or "artists" (default: "songs"). Use "artists" when the user is clearly asking about artists rather than songs.
        - "text_search": free text search on song title + artist name (use only when other filters don't capture the intent)
        - "artist": artist name to filter by
        - "title": song title to filter by
        - "album": album name to filter by
        - "genre": music genre (e.g. "pop", "rock", "hip hop", "dance", "electronic", "r&b", "jazz", "classical", "reggae", "metal")
        - "country": artist country of origin as ISO country code (e.g. "NL" for Dutch/Netherlands, "US" for American, "UK" or "GB" for British, "DE" for German, "BE" for Belgian)
        - "radio_station": radio station name (known stations: #{cached_radio_station_names.join(', ')})
        - "period": time period for when songs were played. Use one of: "hour", "day", "week", "month", "year", "all". Or use granular format like "2_hours", "3_days", "2_weeks", "6_months".
        - "year_from": songs released in or after this year (integer)
        - "year_to": songs released in or before this year (integer)
        - "mood": one of: #{MOOD_MAPPINGS.keys.join(', ')}
        - "sort_by": one of: most_played, newest, popularity (default: most_played)
        - "limit": max results to return (integer, default: 20, max: 50). Use when the user asks for "top N", "most popular", "number 1", etc. For example, "top 3" → limit: 3, "the most popular song" → limit: 1.
        - "lyrics": the lyrics or text snippet the user is searching by (string, for display purposes only)

        Rules:
        - Return ONLY valid JSON, no explanation or markdown.
        - Only include filters that are explicitly or clearly implied by the query.
        - Do not guess or invent filter values that aren't supported.
        - For time references like "this week", "last month", "today", "recently", use the "period" field.
        - "Recent" or "new" means period "month" unless more specific.
        - "Hits" or "popular" implies sort_by "popularity".
        - Understand both English and Dutch queries.
        - When the user mentions lyrics, song text, or quotes part of a song, try to identify the song. If you recognize the lyrics, set "artist" and "title" to the correct song. Always set "lyrics" to the quoted/mentioned lyrics so the user can see what was matched. If you cannot identify the song, set "text_search" to the most distinctive words from the lyrics and still set "lyrics".
      PROMPT
    end

    def cached_radio_station_names
      Rails.cache.fetch('llm:radio_station_names', expires_in: 1.hour) do
        RadioStation.pluck(:name)
      end
    end

    def parse_response(response)
      json = extract_json(response)
      return {} if json.blank?

      parsed = JSON.parse(json)
      return {} unless parsed.is_a?(Hash)

      normalize_filters(parsed)
    rescue JSON::ParserError => e
      Rails.logger.warn("[LLM::QueryTranslator] Failed to parse JSON: #{e.message}")
      {}
    end

    def normalize_filters(parsed)
      filters = extract_string_filters(parsed)
      filters[:search_type] = parsed['search_type'] if SEARCH_TYPES.include?(parsed['search_type'])
      filters[:country] = parsed['country'].upcase if parsed['country'].present? && parsed['country'].upcase.match?(COUNTRY_CODE_PATTERN)
      filters.merge!(extract_numeric_filters(parsed))
      filters.merge!(extract_enum_filters(parsed))
      filters
    end

    def extract_string_filters(parsed)
      STRING_FILTERS.each_with_object({}) do |key, hash|
        hash[key.to_sym] = sanitize_string(parsed[key]) if parsed[key].present?
      end
    end

    def sanitize_string(value)
      return nil unless value.is_a?(String)

      value
        .gsub(/[[:cntrl:]]/, '')
        .strip
        .truncate(MAX_STRING_LENGTH, omission: '')
    end

    def extract_numeric_filters(parsed)
      filters = {}
      filters[:year_from] = parsed['year_from'].to_i if parsed['year_from'].present?
      filters[:year_to] = parsed['year_to'].to_i if parsed['year_to'].present?
      filters[:limit] = [[parsed['limit'].to_i, 50].min, 1].max if parsed['limit'].present?
      filters
    end

    def extract_enum_filters(parsed)
      filters = {}
      filters[:mood] = parsed['mood'] if MOOD_MAPPINGS.key?(parsed['mood'])
      filters[:sort_by] = parsed['sort_by'] if SORT_OPTIONS.include?(parsed['sort_by'])
      filters
    end
  end
end
