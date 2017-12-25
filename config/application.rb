require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

Dotenv::Railtie.load

module RadioPlaylists
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    RSpotify::authenticate("ff70df650ee14a1fad4aed3b533e8ea4", "9899f570bc3e4781b9373e60d6f37095")
    # Set the local time zone
    config.time_zone = "Amsterdam"
    config.active_record.default_timezone = :local
  end
end
