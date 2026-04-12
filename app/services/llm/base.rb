# frozen_string_literal: true

module Llm
  class Base
    include CircuitBreakable

    circuit_breaker_for :claude

    private

    def client
      @client ||= Anthropic::Client.new(
        api_key: ENV.fetch('ANTHROPIC_API_KEY')
      )
    end

    def chat(system_prompt:, user_message:, max_tokens: 1024)
      cache_key = "llm:#{Digest::SHA256.hexdigest("#{system_prompt}#{user_message}")}"

      Rails.cache.fetch(cache_key, expires_in: 1.hour) do
        with_circuit_breaker do
          with_exponential_backoff(max_attempts: 3, base_delay: 1) do
            response = client.messages(
              model: 'claude-haiku-4-5-20251001',
              max_tokens: max_tokens,
              system: system_prompt,
              messages: [{ role: 'user', content: user_message }]
            )
            extract_text(response)
          end
        end
      end
    rescue StandardError => e
      ExceptionNotifier.notify(e)
      Rails.logger.error("[LLM] #{e.class}: #{e.message}")
      nil
    end

    def extract_text(response)
      response.dig('content', 0, 'text')
    end
  end
end
