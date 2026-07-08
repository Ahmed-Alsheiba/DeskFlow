require "test_helper"

module Users
  class RegistrationsControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    test "self-service account deletion is disabled for every role" do
      [ users(:one), users(:two), users(:admin) ].each do |user|
        sign_in user
        assert_no_difference -> { User.count } do
          delete user_registration_path
        end
        assert_redirected_to edit_user_registration_path
        assert User.exists?(user.id)
        sign_out user
      end
    end

    test "the account page no longer offers cancellation" do
      sign_in users(:one)
      get edit_user_registration_path
      assert_response :success
      assert_no_match "Cancel my account", response.body
    end
  end
end
