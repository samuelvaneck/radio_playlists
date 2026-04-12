# frozen_string_literal: true

module Llm
  class Base
    include CircuitBreakable

    circuit_breaker_for :openai

    private

    def client
      @client ||= OpenAI::Client.new(
        access_token: ENV.fetch('OPENAI_API_KEY'),
        request_timeout: 10
      )
    end

    def chat(system_prompt:, user_message:, max_tokens: 1024)
      cache_key = "llm:#{Digest::SHA256.hexdigest("#{system_prompt}#{user_message}")}"

      Rails.cache.fetch(cache_key, expires_in: 1.hour) do
        with_circuit_breaker do
          with_exponential_backoff(max_attempts: 3, base_delay: 1) do
            response = client.chat(
              parameters: {
                model: 'gpt-4.1-mini',
                messages: [
                  { role: 'system', content: system_prompt },
                  { role: 'user', content: user_message }
                ],
                max_tokens: max_tokens,
                temperature: 0
              }
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
      response.dig('choices', 0, 'message', 'content')
    end
  end
end
