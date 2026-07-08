require "test_helper"

# Verifies the Devise activatable hook: a suspended account is blocked from
# signing in and any live session ends on the next request.
class SuspensionTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "a suspended user cannot reach an authenticated page" do
    sign_in users(:suspended)
    get tickets_path
    assert_redirected_to new_user_session_path
  end

  test "suspending an active user ends their session on the next request" do
    user = users(:one)
    sign_in user
    get tickets_path
    assert_response :success

    user.update!(suspended_at: Time.current, suspension_reason: "mid-session")

    get tickets_path
    assert_redirected_to new_user_session_path
  end

  test "a reinstated user can reach authenticated pages again" do
    user = users(:suspended)
    user.update!(suspended_at: nil, suspended_by_id: nil, suspension_reason: nil)
    sign_in user
    get tickets_path
    assert_response :success
  end
end
