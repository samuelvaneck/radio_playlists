require_relative '../../lib/sidekiq/memory_monitor_middleware'

Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDIS_SIDEKIQ_URL'] }

  # Suppress noisy job lifecycle logs (start/done) in production
  # Only log warnings and errors from Sidekiq
  config.logger.level = Logger::WARN if Rails.env.production?

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end

  config.server_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Server
    chain.add Sidekiq::MemoryMonitorMiddleware
  end

  SidekiqUniqueJobs::Server.configure(config)

  SidekiqUniqueJobs.configure do |unique_config|
    unique_config.reaper = :ruby
    unique_config.reaper_count = 1000
    unique_config.reaper_interval = 600
    unique_config.reaper_timeout = 30
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDIS_SIDEKIQ_URL'] }

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end
end
