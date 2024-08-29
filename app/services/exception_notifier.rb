class ExceptionNotifier
  def self.notify_new_relic(exception, tags = nil)
    tags = { message: tags } if tags.is_a?(String)
    NewRelic::Agent.notice_error(exception, custom_params: tags)
  end
end
