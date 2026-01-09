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
  end

  SidekiqUniqueJobs::Server.configure(config)
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDIS_SIDEKIQ_URL'] }

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end
end
