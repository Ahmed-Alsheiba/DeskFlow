require "test_helper"

# Devise lockable: wrong passwords on the sign-in form and on the account page
# share one per-account limit (Devise.maximum_attempts).
class LockoutTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "repeated wrong sign-in passwords lock the account, even against the right password" do
    user = users(:one)
    Devise.maximum_attempts.times do
      post user_session_path, params: { user: { email: user.email, password: "wrong" } }
    end
    assert user.reload.access_locked?

    post user_session_path, params: { user: { email: user.email, password: "password" } }
    get tickets_path
    assert_redirected_to new_user_session_path
  end

  test "a wrong current password on the account page counts toward the lockout" do
    user = users(:one)
    sign_in user
    put user_registration_path, params: { user: { first_name: "New", current_password: "wrong" } }
    assert_equal 1, user.reload.failed_attempts
    assert_equal "Test", user.first_name

    user.update_columns(failed_attempts: Devise.maximum_attempts - 1)
    put user_registration_path, params: { user: { first_name: "New", current_password: "wrong" } }
    assert_redirected_to new_user_session_path
    assert user.reload.access_locked?
  end
end
