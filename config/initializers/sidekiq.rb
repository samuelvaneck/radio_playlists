Sidekiq.configure_server do |config|
  config.redis = { url: YAML.safe_load(ENV['REDIS_SERVER']) }
end

Sidekiq.configure_client do |config| 
  config.redis = { url: YAML.safe_load(ENV['REDIS_SERVER']) }
end
