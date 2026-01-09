# frozen_string_literal: true

class CircuitBreakerConfig
  DEFAULTS = {
    sleep_window: 60,
    volume_threshold: 5,
    error_threshold: 50,
    time_window: 60
  }.freeze

  SERVICES = {
    spotify: {
      sleep_window: 30,
      volume_threshold: 10,
      error_threshold: 40,
      time_window: 60
    },
    itunes: {
      sleep_window: 60,
      volume_threshold: 5,
      error_threshold: 50,
      time_window: 60
    },
    deezer: {
      sleep_window: 60,
      volume_threshold: 5,
      error_threshold: 50,
      time_window: 60
    },
    youtube: {
      sleep_window: 120,
      volume_threshold: 3,
      error_threshold: 30,
      time_window: 60
    },
    lastfm: {
      sleep_window: 90,
      volume_threshold: 5,
      error_threshold: 50,
      time_window: 60
    },
    wikipedia: {
      sleep_window: 60,
      volume_threshold: 5,
      error_threshold: 50,
      time_window: 60
    }
  }.freeze

  class << self
    def for(service_name)
      config = SERVICES.fetch(service_name.to_sym, {})
      DEFAULTS.merge(config)
    end
  end
end
