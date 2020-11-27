# frozen_string_literal: true

class CleaupReadyMailer < ApplicationMailer
  default template_path: 'cleanup_ready_mailer'
  def ready(receiver)
    mail(to: receiver, subject: 'Cleanup ready')
  end
end
