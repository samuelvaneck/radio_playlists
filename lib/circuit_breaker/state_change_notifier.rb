# frozen_string_literal: true

module CircuitBreaker
  class StateChangeNotifier
    def notify(circuit_name, event)
      case event
      when :open
        handle_open(circuit_name)
      when :close
        handle_close(circuit_name)
      when :half_open
        handle_half_open(circuit_name)
      when :success
        Rails.logger.debug { "[CircuitBreaker] #{circuit_name}: success" }
      when :failure
        handle_failure(circuit_name)
      when :skipped
        handle_skipped(circuit_name)
      end
    end

    private

    def handle_open(circuit_name)
      log_state_change(circuit_name, :open, :error)
      send_to_newrelic(circuit_name, :open)
    end

    def handle_close(circuit_name)
      log_state_change(circuit_name, :closed, :info)
      send_to_newrelic(circuit_name, :closed)
    end

    def handle_half_open(circuit_name)
      log_state_change(circuit_name, :half_open, :info)
    end

    def handle_failure(circuit_name)
      Rails.logger.warn("[CircuitBreaker] #{circuit_name}: failure recorded")
    end

    def handle_skipped(circuit_name)
      Rails.logger.warn("[CircuitBreaker] #{circuit_name}: request skipped (circuit open)")
    end

    def log_state_change(circuit_name, state, level)
      message = "[CircuitBreaker] #{circuit_name} state changed to #{state}"
      Rails.logger.public_send(level, message)
    end

    def send_to_newrelic(circuit_name, state)
      NewRelic::Agent.record_custom_event(
        'CircuitBreakerStateChange',
        circuit_name: circuit_name.to_s,
        state: state.to_s,
        timestamp: Time.current.to_i
      )
    rescue StandardError => e
      Rails.logger.error("[CircuitBreaker] Failed to send to NewRelic: #{e.message}")
    end
  end
end
