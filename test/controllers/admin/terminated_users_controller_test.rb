require "test_helper"

module Admin
  class TerminatedUsersControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      @archived = TerminatedUser.create!(
        original_user_id: 999, email: "former@example.com",
        first_name: "Former", last_name: "Employee", role: "staff",
        job_title: "Technician", sector: "IT/Operations",
        submitted_tickets_count: 3, assigned_tickets_count: 2,
        solved_tickets_count: 1, comments_count: 4,
        reason: "Resigned and offboarded.",
        terminated_by_id: users(:admin).id, terminated_by_name: users(:admin).display_name
      )
    end

    test "admin can view the terminated users archive" do
      sign_in users(:admin)
      get admin_terminated_users_path
      assert_response :success
      assert_match "Former Employee", response.body
      assert_match "former@example.com", response.body
      assert_match "Resigned and offboarded.", response.body
    end

    test "manager can view the terminated users archive" do
      sign_in users(:two)
      get admin_terminated_users_path
      assert_response :success
    end

    test "staff cannot view the terminated users archive" do
      sign_in users(:one)
      get admin_terminated_users_path
      assert_redirected_to root_path
    end

    test "preview user sees the archive with masked PII" do
      sign_in users(:preview)
      get admin_terminated_users_path
      assert_response :success
      assert_no_match "former@example.com", response.body
      assert_no_match "Former Employee", response.body
      assert_no_match users(:admin).display_name, response.body
    end

    # --- show (attribution) ------------------------------------------------------------
    test "the detail page lists the archived user's linked tickets and report" do
      archived = users(:one).terminate!(by: users(:admin), reason: "Detailed departure report.")
      sign_in users(:admin)
      get admin_terminated_user_path(archived)
      assert_response :success
      assert_match "Detailed departure report.", response.body
      assert_match tickets(:one).title, response.body          # submitted
      assert_match tickets(:assigned_closed).title, response.body # solved/claimed
    end

    test "the detail page masks PII in preview mode" do
      archived = users(:one).terminate!(by: users(:admin), reason: "gone")
      sign_in users(:preview)
      get admin_terminated_user_path(archived)
      assert_response :success
      assert_no_match archived.email, response.body
    end

    test "an unknown detail page redirects to the index" do
      sign_in users(:admin)
      get admin_terminated_user_path(id: 10_000_000)
      assert_redirected_to admin_terminated_users_path
    end
  end
end
