# frozen_string_literal: true

require_relative 'boot'
require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

Dotenv::Railtie.load

module RadioPlaylists
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set the local time zone
    config.time_zone = "Amsterdam"
    config.active_record.default_timezone = :local

    # Configure Sidekiq as default job handler
    config.active_job.queue_adapter = :sidekiq
    # Fix errors when running jobs with sidekiq
    config.autoload_paths += %W[#{config.root}/app/jobs]
  end
end
