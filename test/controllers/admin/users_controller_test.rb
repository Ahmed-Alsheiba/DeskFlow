require "test_helper"

module Admin
  class UsersControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      @admin   = users(:admin)
      @manager = users(:two)
      @staff   = users(:one)
      @preview = users(:preview)
    end

    # --- show --------------------------------------------------------------------------
    test "admin can view a user's detail page" do
      sign_in @admin
      get admin_user_path(@staff)
      assert_response :success
      assert_match @staff.display_name, response.body
      assert_match @staff.email, response.body
    end

    test "manager can view a user's detail page" do
      sign_in @manager
      get admin_user_path(@staff)
      assert_response :success
    end

    test "staff cannot view the admin user detail page" do
      sign_in @staff
      get admin_user_path(@manager)
      assert_redirected_to root_path
    end

    test "the preview account is not visible as a target" do
      sign_in @admin
      get admin_user_path(@preview)
      assert_redirected_to admin_dashboard_path
    end

    test "remove button only renders when the viewer may remove the user" do
      sign_in @manager
      get admin_user_path(@staff)
      assert_match "remove-user-dialog", response.body
      get admin_user_path(@admin)
      assert_no_match "remove-user-dialog", response.body
    end

    # --- destroy -----------------------------------------------------------------------
    test "admin can terminate a staff user with a reason" do
      sign_in @admin
      assert_difference -> { User.count } => -1, -> { TerminatedUser.count } => 1 do
        delete admin_user_path(@staff), params: { termination: { reason: "Policy violation" } }
      end
      assert_redirected_to admin_dashboard_path
      archived = TerminatedUser.order(:created_at).last
      assert_equal @staff.email, archived.email
      assert_equal "Policy violation", archived.reason
    end

    test "manager can terminate a staff user" do
      sign_in @manager
      assert_difference -> { User.count } => -1, -> { TerminatedUser.count } => 1 do
        delete admin_user_path(@staff), params: { termination: { reason: "Left the company" } }
      end
      assert_redirected_to admin_dashboard_path
    end

    test "manager cannot terminate an admin" do
      sign_in @manager
      assert_no_difference -> { User.count }, -> { TerminatedUser.count } do
        delete admin_user_path(@admin), params: { termination: { reason: "nope" } }
      end
      assert_redirected_to admin_user_path(@admin)
    end

    test "admin cannot terminate themselves" do
      sign_in @admin
      assert_no_difference -> { User.count }, -> { TerminatedUser.count } do
        delete admin_user_path(@admin), params: { termination: { reason: "self" } }
      end
      assert_redirected_to admin_user_path(@admin)
    end

    test "termination requires a reason" do
      sign_in @admin
      assert_no_difference -> { User.count }, -> { TerminatedUser.count } do
        delete admin_user_path(@staff), params: { termination: { reason: "   " } }
      end
      assert_redirected_to admin_user_path(@staff)
    end

    test "terminating an already-removed user redirects gracefully" do
      sign_in @admin
      delete admin_user_path(id: 10_000_000), params: { termination: { reason: "gone" } }
      assert_redirected_to admin_dashboard_path
    end

    test "staff cannot terminate anyone" do
      sign_in @staff
      assert_no_difference -> { User.count }, -> { TerminatedUser.count } do
        delete admin_user_path(users(:three)), params: { termination: { reason: "nope" } }
      end
      assert_redirected_to root_path
    end
  end
end
