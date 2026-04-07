if Rails.env.production? || Rails.env.staging?
  Sentry.init do |config|
    config.dsn = ENV['SENTRY_DSN']
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]
    config.max_breadcrumbs = 20

    config.before_breadcrumb = lambda do |breadcrumb, _hint|
      return nil if breadcrumb.category == 'sql.active_record' && Sidekiq.server?

      breadcrumb
    end

    # Set tracesSampleRate to 1.0 to capture 100%
    # of transactions for performance monitoring.
    # We recommend adjusting this value in production
    # config.traces_sample_rate = 0.5
  end
end
