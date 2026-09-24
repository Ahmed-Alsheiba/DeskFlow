# The "send test email" on the Mail Settings page — confirms an SMTP login actually delivers
# before the app's real mail depends on it.
class MailTestMailer < ApplicationMailer
  # Uses the settings passed in (the unsaved values currently in the form), so the callback
  # that applies the *saved* ones would defeat the purpose.
  skip_after_action :apply_mail_settings

  # Development sets raise_delivery_errors = false, which would make a refused connection
  # look like a successful test. This delivery must report what actually happened.
  after_action { message.raise_delivery_errors = true }

  def test_email(to:, from:, settings:)
    mail(to: to, from: from, subject: "DeskFlow test email", delivery_method_options: settings)
  end
end
