# frozen_string_literal: true

module Llm
  class LyricsSentimentAnalyzer < Base
    MAX_LYRICS_CHARS = 4_000

    attr_reader :raw_response

    def initialize(lyrics:)
      super()
      @lyrics = lyrics.to_s
      @raw_response = {}
    end

    def analyze
      truncated = truncate_lyrics(@lyrics)
      return nil if truncated.blank?

      response = chat(system_prompt: system_prompt, user_message: truncated, max_tokens: 256)
      @raw_response = { request_chars: truncated.length, response: response }
      return nil if response.blank?

      parse_response(response)
    end

    private

    def truncate_lyrics(text)
      text.length > MAX_LYRICS_CHARS ? text[0, MAX_LYRICS_CHARS] : text
    end

    def system_prompt
      <<~PROMPT
        You are a music lyrics analyst. You receive song lyrics in any language (Dutch, English, etc.).
        Output a JSON object describing the lyrics on these axes:

        - "sentiment": float in [-1.0, 1.0]. -1 = very negative/sad/angry, 0 = neutral/mixed, +1 = very positive/joyful.
        - "themes": array of 1-5 short lowercase theme tags chosen from this controlled list:
          love, heartbreak, loss, nostalgia, hope, faith, party, dance, friendship, family,
          empowerment, rebellion, social, political, money, fame, sex, loneliness, anxiety,
          anger, peace, nature, travel, summer, winter, christmas, drugs, violence, freedom, work
        - "language": ISO 639-1 code of the dominant language ("nl", "en", "de", "fr", "es", "it", "tr", "ar", etc.).
        - "confidence": float in [0.0, 1.0] expressing how confident you are in the sentiment score.

        If the lyrics are too short, garbled, or otherwise unanalyzable, return:
        {"sentiment": null, "themes": [], "language": null, "confidence": 0.0}

        Return ONLY the JSON object. No explanation, no code fences.
      PROMPT
    end

    def parse_response(response)
      json = extract_json(response)
      return nil if json.blank?

      parsed = JSON.parse(json)
      return nil unless parsed.is_a?(Hash)

      {
        sentiment: clamp_float(parsed['sentiment'], -1.0, 1.0),
        themes: extract_themes(parsed['themes']),
        language: parsed['language'].presence,
        confidence: clamp_float(parsed['confidence'], 0.0, 1.0)
      }
    rescue JSON::ParserError => e
      Rails.logger.warn("[LLM::LyricsSentimentAnalyzer] Failed to parse JSON: #{e.message}")
      nil
    end

    def clamp_float(value, min, max)
      return nil if value.nil?

      value.to_f.clamp(min, max)
    end

    def extract_themes(themes)
      return [] unless themes.is_a?(Array)

      themes.filter_map { |t| t.to_s.downcase.strip.presence }.uniq.first(5)
    end
  end
end
