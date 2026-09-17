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
    test "admin can terminate a staff user with a reason and the user is emailed" do
      sign_in @admin
      assert_difference -> { User.count } => -1, -> { TerminatedUser.count } => 1 do
        perform_enqueued_jobs do
          delete admin_user_path(@staff), params: { termination: { reason: "Policy violation", password: "password" } }
        end
      end
      assert_redirected_to admin_dashboard_path
      archived = TerminatedUser.order(:created_at).last
      assert_equal @staff.email, archived.email
      assert_equal "Policy violation", archived.reason

      mail = ActionMailer::Base.deliveries.last
      assert_equal [ @staff.email ], mail.to
      assert_no_match "Policy violation", mail.body.encoded
    end

    test "manager can terminate a staff user" do
      sign_in @manager
      assert_difference -> { User.count } => -1, -> { TerminatedUser.count } => 1 do
        delete admin_user_path(@staff), params: { termination: { reason: "Left the company", password: "password" } }
      end
      assert_redirected_to admin_dashboard_path
    end

    test "termination requires the acting admin's correct password" do
      sign_in @admin
      assert_no_difference -> { User.count }, -> { TerminatedUser.count } do
        assert_no_enqueued_emails do
          delete admin_user_path(@staff), params: { termination: { reason: "Typed report survives", password: "wrong" } }
        end
      end
      assert_response :unprocessable_entity
      assert_match "Typed report survives", response.body
      assert_match "Incorrect password", response.body
    end

    test "repeated wrong removal passwords lock the admin and end the session" do
      sign_in @admin
      (Devise.maximum_attempts - 1).times do
        delete admin_user_path(@staff), params: { termination: { reason: "x", password: "wrong" } }
        assert_response :unprocessable_entity
      end
      delete admin_user_path(@staff), params: { termination: { reason: "x", password: "wrong" } }
      assert_redirected_to new_user_session_path
      assert @admin.reload.access_locked?
      assert User.exists?(@staff.id)

      get admin_dashboard_path
      assert_redirected_to new_user_session_path
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

    # --- suspend / reinstate -----------------------------------------------------------
    test "admin can suspend a staff user with a reason" do
      sign_in @admin
      patch suspend_admin_user_path(@staff), params: { suspension: { reason: "Under review", password: "password" } }
      assert_redirected_to admin_user_path(@staff)
      @staff.reload
      assert @staff.suspended?
      assert_equal @admin.id, @staff.suspended_by_id
      assert_equal "Under review", @staff.suspension_reason
    end

    test "suspension requires the acting admin's correct password" do
      sign_in @admin
      patch suspend_admin_user_path(@staff), params: { suspension: { reason: "Typed reason survives", password: "wrong" } }
      assert_response :unprocessable_entity
      assert_match "Typed reason survives", response.body
      assert_match "suspend-user-dialog-#{@staff.id}').showModal()", response.body
      assert_not @staff.reload.suspended?
    end

    test "suspension requires a reason" do
      sign_in @admin
      patch suspend_admin_user_path(@staff), params: { suspension: { reason: "  " } }
      assert_redirected_to admin_user_path(@staff)
      assert_not @staff.reload.suspended?
    end

    test "manager cannot suspend an admin" do
      sign_in @manager
      patch suspend_admin_user_path(@admin), params: { suspension: { reason: "nope" } }
      assert_redirected_to admin_user_path(@admin)
      assert_not @admin.reload.suspended?
    end

    test "admin can reinstate a suspended user" do
      @staff.update!(suspended_at: Time.current, suspended_by_id: @admin.id, suspension_reason: "x")
      sign_in @admin
      patch reinstate_admin_user_path(@staff)
      assert_redirected_to admin_user_path(@staff)
      assert_not @staff.reload.suspended?
    end

    # --- unlock -------------------------------------------------------------------------
    test "admin sees the locked state and can unlock a locked user" do
      @staff.lock_access!(send_instructions: false)
      sign_in @admin
      get admin_user_path(@staff)
      assert_match "Unlock User", response.body

      patch unlock_admin_user_path(@staff)
      assert_redirected_to admin_user_path(@staff)
      assert_not @staff.reload.access_locked?
      assert_equal 0, @staff.failed_attempts
    end

    test "manager cannot unlock an admin" do
      @admin.lock_access!(send_instructions: false)
      sign_in @manager
      patch unlock_admin_user_path(@admin)
      assert_redirected_to admin_user_path(@admin)
      assert @admin.reload.access_locked?
    end

    test "staff cannot suspend anyone" do
      sign_in @staff
      patch suspend_admin_user_path(users(:three)), params: { suspension: { reason: "nope" } }
      assert_redirected_to root_path
      assert_not users(:three).reload.suspended?
    end
  end
end
