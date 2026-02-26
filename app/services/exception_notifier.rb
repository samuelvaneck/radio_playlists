class ExceptionNotifier
  def self.notify(exception, tags = nil)
    tags = { message: tags } if tags.is_a?(String)
    Sentry.capture_exception(exception, extra: tags)
  end
end
