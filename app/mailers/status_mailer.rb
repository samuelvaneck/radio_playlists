class StatusMailer < ApplicationMailer
  default template_path: 'status_mailer'
  def status_mail(receiver, results)
    @results = results
    mail(to: receiver, subject: 'Status radiostation playlists')
  end
end
