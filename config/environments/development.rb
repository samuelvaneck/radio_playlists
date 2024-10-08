Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  config.action_controller.perform_caching = true

  config.cache_store = :redis_cache_store, { url: ENV['REDIS_CACHE_URL'] }
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{2.days.seconds.to_i}"
  }

  # mailer options
  config.action_mailer.delivery_method = :letter_opener
  config.action_mailer.perform_deliveries = true
  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  # config.assets.debug = true

  # Suppress logger output for asset requests.
  # config.assets.quiet = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::FileUpdateChecker

  # enable mailser preview
  config.action_mailer.show_previews = true

  # If you're using RSpec make sure to add the link changing where the previews path is.
  # config.action_mailer.preview_path ||= defined?(Rails.root) ? "#{Rails.root}/spec/mailers/previews" : nil

  # Store files locally.
  # config.active_storage.service = :local

  config.log_level = :debug
  logger           = ActiveSupport::Logger.new(STDOUT)
  logger.formatter = config.log_formatter
  config.logger = ActiveSupport::TaggedLogging.new(logger)

  config.web_console.permissions = '172.16.0.1/12'

  config.after_initialize do
    Bullet.enable = true
    Bullet.alert = false
    Bullet.bullet_logger = true
    Bullet.console = true
    Bullet.rails_logger = true
    Bullet.add_footer = true
    Bullet.skip_html_injection = false
  end
end
