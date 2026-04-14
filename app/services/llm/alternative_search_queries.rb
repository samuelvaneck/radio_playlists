# frozen_string_literal: true

module Llm
  class AlternativeSearchQueries < Base
    MAX_QUERIES = 3

    attr_reader :raw_response

    def initialize(artist_name:, title:)
      super()
      @artist_name = artist_name
      @title = title
      @raw_response = {}
    end

    def generate
      response = chat(system_prompt: system_prompt, user_message: user_message, max_tokens: 256)
      @raw_response = { request: user_message.strip, response: response }
      return [] if response.blank?

      parse_queries(response)
    end

    private

    def system_prompt
      <<~PROMPT
        You are a music search expert. A Spotify search for a song returned no results.
        Generate 2-3 alternative search queries that might find the song.

        Consider:
        - Simplifying complex artist names: try just the primary band/group name without collaborators
          (e.g., "Opwekking Band met Marcel Zimmer" → "Opwekking", "André Rieu & Johann Strauss Orchestra" → "André Rieu")
        - Removing featured artists from the title or artist field
        - Fixing common .titleize capitalization errors (e.g., "Dj" → "DJ", "Mc" → "MC")
        - Restoring special characters (e.g., "Tiesto" → "Tiësto", "Beyonce" → "Beyoncé")
        - Trying the international/English title if it looks like a Dutch translation
        - Removing parenthetical suffixes like "(Radio Edit)", "(Official Audio)", "(Live)"
        - Handling track/catalog numbers: move to parentheses or remove
          (e.g., "785 Fundament" → "Fundament" or "Fundament (785)")
        - Removing radio station tags or prefixes from the title
        - Simplifying punctuation

        Return ONLY a JSON array of objects with "artist" and "title" keys. No explanation.
        Example: [{"artist": "Tiësto", "title": "Red Lights"}, {"artist": "DJ Tiësto", "title": "Red Lights"}]
      PROMPT
    end

    def user_message
      "Artist: #{@artist_name}\nTitle: #{@title}"
    end

    def parse_queries(response)
      json = extract_json(response)
      return [] if json.blank?

      parsed = JSON.parse(json)
      return [] unless parsed.is_a?(Array)

      parsed.select { |q| q['artist'].present? && q['title'].present? }.first(MAX_QUERIES)
    rescue JSON::ParserError => e
      Rails.logger.warn("[LLM::AlternativeSearchQueries] Failed to parse JSON: #{e.message}")
      []
    end
  end
end
