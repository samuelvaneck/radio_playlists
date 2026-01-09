# frozen_string_literal: true

module CircuitBreakable
  extend ActiveSupport::Concern

  class CircuitOpenError < StandardError
    attr_reader :service_name

    def initialize(service_name)
      @service_name = service_name
      super("Circuit breaker open for #{service_name}")
    end
  end

  class RateLimitError < StandardError
    attr_reader :retry_after

    def initialize(retry_after = 30)
      @retry_after = retry_after
      super("Rate limited, retry after #{retry_after} seconds")
    end
  end

  included do
    class_attribute :circuit_breaker_service_name, default: nil
  end

  class_methods do
    def circuit_breaker_for(service_name)
      self.circuit_breaker_service_name = service_name
    end
  end

  private

  def circuit_breaker
    @circuit_breaker ||= Circuitbox.circuit(
      circuit_breaker_service_name,
      **circuit_options
    )
  end

  def circuit_options
    config = CircuitBreakerConfig.for(circuit_breaker_service_name)
    {
      sleep_window: config[:sleep_window],
      volume_threshold: config[:volume_threshold],
      error_threshold: config[:error_threshold],
      time_window: config[:time_window],
      exceptions: [Faraday::Error, Faraday::TimeoutError, Faraday::ConnectionFailed, RateLimitError]
    }
  end

  def with_circuit_breaker(&block)
    circuit_breaker.run(&block)
  rescue Circuitbox::OpenCircuitError => e
    handle_circuit_failure(e)
  end

  def handle_circuit_failure(error)
    log_circuit_state(:open)
    ExceptionNotifier.notify_new_relic(
      error,
      { service: circuit_breaker_service_name, circuit_state: 'open' }
    )
    nil
  end

  def log_circuit_state(state)
    Rails.logger.warn("[CircuitBreaker] Service: #{circuit_breaker_service_name}, State: #{state}")
  end

  def with_exponential_backoff(max_attempts: 3, base_delay: 1)
    attempts = 0
    begin
      attempts += 1
      yield
    rescue Faraday::Error, Faraday::TimeoutError, Faraday::ConnectionFailed, RateLimitError => e
      raise e unless attempts < max_attempts

      delay = base_delay * (2**(attempts - 1)) + rand(0.0..0.5)
      sleep(delay)
      retry
    end
  end

  def handle_rate_limit_response(response)
    return unless response.status == 429

    retry_after = response.headers['Retry-After']&.to_i || 30
    Rails.logger.warn(
      "[CircuitBreaker] #{circuit_breaker_service_name} rate limited. Retry-After: #{retry_after}s"
    )
    raise RateLimitError, retry_after
  end
end
