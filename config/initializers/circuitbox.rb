# frozen_string_literal: true

require 'circuitbox'

# Configure Circuitbox circuit breaker defaults
# Use memory store for all environments (thread-safe in-memory storage)
# Redis store could be used in production for distributed state across Sidekiq workers
Circuitbox.configure do |config|
  config.default_circuit_store = Circuitbox::MemoryStore.new
end
