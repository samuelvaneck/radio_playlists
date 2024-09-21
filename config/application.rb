require_relative "boot"

# require "rails/all"
require "rails"

# Serves as documentation of frameworks that would have been loaded by rails/all, but which we don't use.
# [
#   'action_cable/engine',
#   'action_mailbox/engine',
#   'action_text/engine',
#   'active_job/railtie',
#   'action_view/railtie'
# ]

# Load frameworks we are using
%w[
  active_record/railtie
  action_controller/railtie
  action_mailer/railtie
  active_storage/engine
  rails/test_unit/railtie
].each do |railtie|
  require railtie
rescue LoadError => exception
  # Rails really swallows errors by default.
  puts "Could not load #{railtie}: #{exception}"
end

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module RadioPlaylists
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "Amsterdam"

    config.after_initialize do
      puts "Database: #{Rails.configuration.database_configuration.dig(Rails.env, 'database')}"
    end
  end
end
