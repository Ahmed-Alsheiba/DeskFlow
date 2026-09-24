require "test_helper"

module Admin
  class MailSettingsControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      @admin   = users(:admin)
      @manager = users(:two)
      @staff   = users(:one)
      @setting = MailSetting.current
    end

    # --- access ------------------------------------------------------------------------
    test "admin can open the form" do
      sign_in @admin
      get edit_admin_mail_settings_path
      assert_response :success
      assert_match "smtp.example.test", response.body
    end

    test "managers and staff are turned away" do
      [ @manager, @staff ].each do |user|
        sign_in user
        get edit_admin_mail_settings_path
        assert_redirected_to root_path
      end
    end

    # --- update ------------------------------------------------------------------------
    test "admin can save settings with their password" do
      sign_in @admin
      patch admin_mail_settings_path, params: { mail_setting: {
        enabled: "1", address: "smtp.resend.com", port: "465", user_name: "resend",
        password: "new-key", from_address: "no-reply@deskflow.test"
      }, current_password: "password" }
      assert_redirected_to edit_admin_mail_settings_path
      @setting.reload
      assert_equal "smtp.resend.com", @setting.address
      assert_equal 465, @setting.port
      assert_equal "new-key", @setting.password
    end

    test "saving requires the admin's correct password" do
      sign_in @admin
      patch admin_mail_settings_path, params: { mail_setting: {
        address: "smtp.evil.test"
      }, current_password: "wrong" }
      assert_response :unprocessable_entity
      assert_match "Incorrect password", response.body
      assert_equal "smtp.example.test", @setting.reload.address
    end

    test "a blank password keeps the stored one" do
      sign_in @admin
      patch admin_mail_settings_path, params: { mail_setting: {
        user_name: "changed", password: ""
      }, current_password: "password" }
      assert_redirected_to edit_admin_mail_settings_path
      @setting.reload
      assert_equal "changed", @setting.user_name
      assert_equal "test-smtp-password", @setting.password
    end

    test "the toggle can be switched off" do
      sign_in @admin
      patch admin_mail_settings_path, params: { mail_setting: { enabled: "0" }, current_password: "password" }
      assert_not @setting.reload.enabled?
    end

    # --- test email --------------------------------------------------------------------
    test "test email uses the values in the form, not the saved ones" do
      sign_in @admin
      assert_emails 1 do
        post test_admin_mail_settings_path, params: { mail_setting: {
          address: "smtp.unsaved.test", user_name: "unsaved", password: "unsaved-key",
          from_address: "unsaved@example.test"
        } }
      end
      assert_response :success
      assert JSON.parse(response.body)["ok"]

      mail = ActionMailer::Base.deliveries.last
      assert_equal [ @admin.email ], mail.to
      assert_equal [ "unsaved@example.test" ], mail.from
      assert_equal "smtp.example.test", @setting.reload.address, "the test must not save anything"
    end

    test "test email reports missing settings instead of failing" do
      sign_in @admin
      assert_no_emails do
        post test_admin_mail_settings_path, params: { mail_setting: { address: "", user_name: "", password: "" } }
      end
      body = JSON.parse(response.body)
      assert_not body["ok"]
      assert_match "Fill in", body["message"]
    end

    test "staff cannot send a test email" do
      sign_in @staff
      post test_admin_mail_settings_path, params: { mail_setting: { address: "smtp.example.test" } }
      assert_redirected_to root_path
    end
  end
end
