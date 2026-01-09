# frozen_string_literal: true

module CircuitBreakerHelpers
  def reset_circuit_store
    # Clear the cached circuits so new circuits use the fresh store
    Circuitbox.instance_variable_set(:@cached_circuits, {})
    Circuitbox.configure do |c|
      c.default_circuit_store = Circuitbox::MemoryStore.new
    end
  end

  def open_circuit(service_name)
    config = CircuitBreakerConfig.for(service_name)
    circuit = Circuitbox.circuit(
      service_name,
      sleep_window: config[:sleep_window],
      volume_threshold: config[:volume_threshold],
      error_threshold: config[:error_threshold],
      time_window: config[:time_window],
      exceptions: [StandardError]
    )

    (config[:volume_threshold] + 1).times do
      circuit.run { raise StandardError, 'Forced failure' }
    rescue StandardError
      # Expected
    end
  end

  def circuit_open?(service_name)
    config = CircuitBreakerConfig.for(service_name)
    circuit = Circuitbox.circuit(
      service_name,
      sleep_window: config[:sleep_window],
      volume_threshold: config[:volume_threshold],
      error_threshold: config[:error_threshold],
      time_window: config[:time_window],
      exceptions: [StandardError]
    )
    circuit.open?
  end
end

RSpec.configure do |config|
  config.include CircuitBreakerHelpers

  config.before do
    reset_circuit_store
  end
end
