class StatusMailer < ApplicationMailer
  def send_email(receiver, results)
    mail(to: receiver, subject: 'Status radiostation playlists') do
      results
    end
  end
end
