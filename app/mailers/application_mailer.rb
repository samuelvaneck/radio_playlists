class ApplicationMailer < ActionMailer::Base
  default :from => 'Status <status@radioplaylists.samuelvaneck.com>'
  layout 'mailer'
end
