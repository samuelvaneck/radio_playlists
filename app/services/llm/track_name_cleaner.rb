# frozen_string_literal: true

module Llm
  class TrackNameCleaner < Base
    attr_reader :raw_response

    def initialize(artist_name:, title:)
      super()
      @artist_name = artist_name
      @title = title
      @raw_response = {}
    end

    def clean
      response = chat(system_prompt: system_prompt, user_message: user_message, max_tokens: 256)
      @raw_response = { request: user_message.strip, response: response }
      return nil if response.blank?

      parse_response(response)
    end

    private

    def system_prompt
      <<~PROMPT
        You are a music metadata expert. You receive raw artist name and song title from a Dutch radio station
        scraper or audio recognizer. Clean them up so they can be used to search on Spotify.

        Fix these common issues:
        - .titleize capitalization errors: "Dj Tiesto" → "DJ Tiësto", "Mc Hammer" → "MC Hammer"
        - Missing diacritics: "Beyonce" → "Beyoncé", "Tiesto" → "Tiësto", "Suze" → "Suzé"
        - Radio station tags in titles: remove station names, "Radio 538 versie", etc.
        - Chart position prefixes: "#1: ", "89. ", etc.
        - Unnecessary suffixes: "(Official Audio)", "(Official Video)", "(Lyric Video)"
        - Featured artists in the wrong field: move them from title to artist if needed
        - Combined artist names: keep them but fix spelling/capitalization

        Return ONLY a JSON object with "artist" and "title" keys. No explanation.
        Example: {"artist": "DJ Tiësto", "title": "Red Lights"}
      PROMPT
    end

    def user_message
      "Artist: #{@artist_name}\nTitle: #{@title}"
    end

    def parse_response(response)
      json = extract_json(response)
      return nil if json.blank?

      parsed = JSON.parse(json)
      return nil unless parsed.is_a?(Hash) && parsed['artist'].present? && parsed['title'].present?
      return nil if parsed['artist'] == @artist_name && parsed['title'] == @title

      parsed
    rescue JSON::ParserError => e
      Rails.logger.warn("[LLM::TrackNameCleaner] Failed to parse JSON: #{e.message}")
      nil
    end
  end
end
