class ApplicationMailer < ActionMailer::Base
  # Sender and SMTP connection both come from the MailSetting row (with a credentials
  # fallback), resolved at delivery time — so saving Admin → Mail Settings takes effect
  # without a restart. Devise's mailer inherits this class (config.parent_mailer), so
  # password-reset and unlock mail goes through the same wiring.
  default from: -> { MailSetting.current.mail_from }
  layout "mailer"

  after_action :apply_mail_settings

  private

  def apply_mail_settings
    setting = MailSetting.current
    if !setting.deliver?
      # Toggled off or not configured: skip quietly rather than raising on every send.
      message.perform_deliveries = false
    elsif ActionMailer::Base.delivery_method == :smtp
      # Guarded so the test environment keeps its :test delivery method.
      message.delivery_method(:smtp, setting.smtp_settings)
    end
  end
end
