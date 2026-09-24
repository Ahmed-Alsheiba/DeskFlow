require "test_helper"

# ApplicationMailer#apply_mail_settings is the single choke point every delivery passes
# through, so the on/off toggle is tested here rather than per mailer.
class UserMailerTest < ActionMailer::TestCase
  setup do
    @archived = TerminatedUser.create!(original_user_id: users(:one).id, email: "gone@example.com",
                                       first_name: "Gone", last_name: "Away", role: "staff", reason: "left",
                                       terminated_by_id: users(:admin).id, terminated_by_name: "Admin User")
  end

  test "delivers while mail is enabled" do
    assert_emails 1 do
      UserMailer.with(terminated_user: @archived).removed.deliver_now
    end
    assert_equal [ "helpdesk@example.test" ], ActionMailer::Base.deliveries.last.from
  end

  test "delivers nothing while mail is toggled off" do
    MailSetting.current.update!(enabled: false)
    assert_no_emails do
      UserMailer.with(terminated_user: @archived).removed.deliver_now
    end
  end

  test "delivers nothing when no SMTP login is configured" do
    MailSetting.current.update!(user_name: "", password: "")
    assert_no_emails do
      UserMailer.with(terminated_user: @archived).removed.deliver_now
    end
  end
end
