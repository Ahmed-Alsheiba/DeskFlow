# App-wide SMTP configuration, held in a single row and editable at Admin → Mail Settings.
# It supersedes the deploy-time wiring (the smtp block in credentials, read by
# config/environments/production.rb), but every field falls back to that source when blank,
# so an instance configured the old way keeps working and nothing needs a redeploy after.
#
# The SMTP password is the one real secret here, so it's encrypted at rest with Active Record
# Encryption (keys in credentials for dev/prod; fixed test keys in config/environments/test.rb).
class MailSetting < ApplicationRecord
  encrypts :password

  # Offered as dropdowns on the form, with a "Custom…" escape hatch. Presentation data only —
  # the stored value is a plain host/port, so nothing else depends on these lists.
  SMTP_HOSTS = {
    "Resend"                  => "smtp.resend.com",
    "SendGrid"                => "smtp.sendgrid.net",
    "Mailgun"                 => "smtp.mailgun.org",
    "Postmark"                => "smtp.postmarkapp.com",
    "Brevo"                   => "smtp-relay.brevo.com",
    "Gmail / Google Workspace" => "smtp.gmail.com",
    "Outlook / Microsoft 365" => "smtp.office365.com",
    "Zoho"                    => "smtp.zoho.com"
  }.freeze

  SMTP_PORTS = {
    "587 (STARTTLS)" => 587,
    "465 (SSL/TLS)"  => 465,
    "2525"           => 2525,
    "25"             => 25
  }.freeze

  # What each provider expects as the SMTP username — shown as the field's placeholder.
  USER_NAME_HINTS = {
    "smtp.resend.com"     => "resend",
    "smtp.sendgrid.net"   => "apikey",
    "smtp.mailgun.org"    => "postmaster@mg.yourdomain.com",
    "smtp.postmarkapp.com" => "your Server API token",
    "smtp-relay.brevo.com" => "your Brevo login",
    "smtp.gmail.com"      => "you@yourdomain.com (app password)",
    "smtp.office365.com"  => "you@yourdomain.com",
    "smtp.zoho.com"       => "you@yourdomain.com"
  }.freeze

  # Blank fields are legitimate — they mean "fall back to credentials" — so only the shape of
  # what's filled in is validated. Whether there's enough to send is `configured?`.
  validates :port, numericality: { only_integer: true, in: 1..65_535 }, allow_nil: true
  validates :from_address, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  # The single row. Not a class of records — there is exactly one mail configuration.
  def self.current
    first_or_create!
  end

  # Each accessor prefers the DB value, then the credentials block it replaces, so the two
  # can coexist during and after the move off deploy-time config.
  def resolved_address   = address.presence || Rails.application.credentials.dig(:smtp, :address)
  def resolved_port      = port || Rails.application.credentials.dig(:smtp, :port) || 587
  def resolved_user_name = user_name.presence || Rails.application.credentials.dig(:smtp, :user_name)
  def resolved_password  = password.presence || Rails.application.credentials.dig(:smtp, :password)

  # `from` must never be nil (an invalid sender breaks delivery), so it keeps the same
  # last-resort default ApplicationMailer used before.
  def mail_from
    from_address.presence || Rails.application.credentials.dig(:smtp, :from) || "no-reply@deskflow.dev"
  end

  # The Action Mailer smtp_settings hash, built per delivery so a form save takes effect
  # without a restart. TLS mode is inferred from the port so any provider works: 465 speaks
  # TLS from the first byte (implicit), everything else (587/2525/25) upgrades via STARTTLS.
  def smtp_settings
    tls = resolved_port.to_i == 465 ? { tls: true } : { enable_starttls_auto: true }
    {
      address:        resolved_address,
      port:           resolved_port,
      user_name:      resolved_user_name,
      password:       resolved_password,
      authentication: :plain
    }.merge(tls)
  end

  # Enough to actually authenticate to a server. Unconfigured instances skip sending quietly
  # instead of raising on every delivery.
  def configured? = resolved_address.present? && resolved_user_name.present? && resolved_password.present?

  def deliver? = enabled? && configured?
end
