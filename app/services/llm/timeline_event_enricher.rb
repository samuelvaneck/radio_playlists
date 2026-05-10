# frozen_string_literal: true

module Llm
  class TimelineEventEnricher < Base
    MAX_ARTICLE_CHARS = 10_000
    MAX_TOKENS = 4096
    REQUEST_TIMEOUT = 60

    def initialize(events:, article_text:, artist_name:)
      super()
      @events = events.to_a
      @article_text = article_text.to_s
      @artist_name = artist_name.to_s
    end

    def call
      return @events if @events.empty? || @article_text.blank?

      response = chat(system_prompt: system_prompt, user_message: user_message, max_tokens: MAX_TOKENS)
      return @events if response.blank?

      enrichments = parse_response(response)
      return @events if enrichments.blank?

      merge_enrichments(enrichments)
    end

    private

    def client
      @client ||= OpenAI::Client.new(access_token: ENV.fetch('OPENAI_API_KEY'), request_timeout: REQUEST_TIMEOUT)
    end

    def system_prompt
      <<~PROMPT
        You enrich a music-artist timeline with grounded summaries based on a Wikipedia article.

        Input:
        - The artist's Wikipedia article text.
        - A JSON array of timeline events. Each event has: index, category, date, title.

        For each event, decide:
        - "summary": a 1-2 sentence factual description, ONLY using information present in the article. If the event is not mentioned, set null. Do NOT invent facts, dates, or quotes.
        - "notable": true if the article explicitly discusses this event (e.g. covers an album in detail, mentions an award by name). Otherwise false. Compilation albums, live recordings, interview releases, and minor reissues should usually be notable=false unless the article highlights them.

        Output ONLY a JSON object with key "enrichments" mapping to an array. Each item: {"index": <int>, "summary": <string|null>, "notable": <bool>}.
        Include EVERY input event index exactly once. Match the order of the input events. No prose, no code fences.
      PROMPT
    end

    def user_message
      <<~MSG
        Artist: #{@artist_name}

        Wikipedia article (truncated):
        #{truncate_article}

        Events:
        #{events_json}
      MSG
    end

    def truncate_article
      stripped = ActionController::Base.helpers.strip_tags(@article_text).gsub(/\s+/, ' ').strip
      stripped.length > MAX_ARTICLE_CHARS ? stripped[0, MAX_ARTICLE_CHARS] : stripped
    end

    def events_json
      indexed = @events.each_with_index.map do |event, index|
        { 'index' => index, 'category' => event['category'], 'date' => event['date'], 'title' => event['title'] }
      end
      JSON.generate(indexed)
    end

    def parse_response(response)
      json = extract_json(response)
      return nil if json.blank?

      parsed = JSON.parse(json)
      enrichments = parsed.is_a?(Hash) ? parsed['enrichments'] : parsed
      return nil unless enrichments.is_a?(Array)

      enrichments.each_with_object({}) do |entry, acc|
        next unless entry.is_a?(Hash)

        index = entry['index']
        next unless index.is_a?(Integer)

        acc[index] = {
          'summary' => entry['summary'].is_a?(String) ? entry['summary'].strip.presence : nil,
          'notable' => entry['notable'] == true
        }
      end
    rescue JSON::ParserError => e
      Rails.logger.warn("[LLM::TimelineEventEnricher] Failed to parse JSON: #{e.message}")
      nil
    end

    def merge_enrichments(enrichments)
      @events.each_with_index.map do |event, index|
        enrichment = enrichments[index] || {}
        event.merge('summary' => enrichment['summary'], 'notable' => enrichment.fetch('notable', false))
      end
    end
  end
end
