class ApplicationMailer < ActionMailer::Base
  default from: Rails.application.credentials.dig(:smtp, :from) || "no-reply@deskflow.dev"
  layout "mailer"
end
