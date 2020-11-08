# Preview all emails at http://localhost:3000/rails/mailers/status_mailer
class StatusMailerPreview < ActionMailer::Preview
  def status_mail
    radio_station = Radiostation.first
    StatusMailer.with(receiver: 'test@test.com', results: { "#{radio_station.name}": radio_station.status }).status_mail
  end
end
