require "test_helper"

class MailSettingTest < ActiveSupport::TestCase
  setup { @setting = MailSetting.current }

  test "current is a singleton row" do
    assert_equal @setting.id, MailSetting.current.id
    assert_equal 1, MailSetting.count
  end

  test "the password is encrypted at rest" do
    assert_equal "test-smtp-password", @setting.reload.password
    assert_not_includes MailSetting.connection.select_value("SELECT password FROM mail_settings").to_s,
                        "test-smtp-password"
  end

  test "blank fields fall back to credentials, then to a default sender" do
    @setting.update!(address: "", user_name: "", from_address: "")
    # No smtp block in the test credentials, so these resolve to nil / the last-resort default.
    assert_nil @setting.resolved_address
    assert_nil @setting.resolved_user_name
    assert_equal "no-reply@deskflow.dev", @setting.mail_from
    assert_equal 587, @setting.resolved_port
  end

  test "TLS mode follows the port" do
    assert @setting.smtp_settings[:enable_starttls_auto]
    assert_nil @setting.smtp_settings[:tls]

    @setting.port = 465
    assert @setting.smtp_settings[:tls]
    assert_nil @setting.smtp_settings[:enable_starttls_auto]
  end

  test "deliver? needs both the toggle and a complete login" do
    assert @setting.deliver?

    @setting.enabled = false
    assert_not @setting.deliver?

    @setting.enabled = true
    @setting.user_name = ""
    assert_not @setting.configured?
    assert_not @setting.deliver?
  end

  test "an invalid from address is rejected but a blank one is fine" do
    assert_not @setting.update(from_address: "not-an-email")
    assert @setting.update(from_address: "")
  end
end
