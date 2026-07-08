require "test_helper"

# Locks in the read-only preview/demo guarantees: a preview-role session can browse
# everything we expose but can never mutate data, and real PII is masked.
class PreviewModeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @preview = users(:preview)
    @staff   = users(:one)
    @ticket  = tickets(:one) # unassigned, status "Open"
  end

  # --- Entry / exit ------------------------------------------------------------------
  test "an unauthenticated visitor can enter preview via POST /preview" do
    post preview_path
    assert_redirected_to tickets_path
    follow_redirect!
    assert_response :success
  end

  test "preview user can sign out to exit preview" do
    sign_in @preview
    delete destroy_user_session_path
    assert_response :redirect
  end

  test "sign-up CTA exits preview and reaches registration without an 'already signed in' bounce" do
    sign_in @preview
    delete preview_path, params: { to: "signup" }
    assert_redirected_to new_user_registration_path
    follow_redirect!
    assert_response :success # signed out first, so Devise renders the form
  end

  test "login CTA exits preview and reaches the sign-in page" do
    sign_in @preview
    delete preview_path, params: { to: "login" }
    assert_redirected_to new_user_session_path
    follow_redirect!
    assert_response :success
  end

  # --- Read access -------------------------------------------------------------------
  test "preview user can view the tickets index, a ticket, and the admin dashboard" do
    sign_in @preview
    get tickets_path
    assert_response :success
    get ticket_path(@ticket)
    assert_response :success
    get admin_dashboard_path
    assert_response :success
  end

  test "preview user can open the read-only new and edit forms" do
    sign_in @preview
    get new_ticket_path
    assert_response :success
    get edit_ticket_path(@ticket)
    assert_response :success
  end

  # --- Writes blocked (server-side defense-in-depth) ---------------------------------
  test "preview user cannot create a ticket" do
    sign_in @preview
    assert_no_difference -> { Ticket.count } do
      post tickets_path, params: { ticket: { title: "x", description: "y", category: "Hardware", priority: "Low", status: "Open" } }
    end
    assert_response :redirect
  end

  test "preview user cannot update a ticket" do
    sign_in @preview
    original = @ticket.title
    patch ticket_path(@ticket), params: { ticket: { title: "hacked" } }
    assert_response :redirect
    assert_equal original, @ticket.reload.title
  end

  test "preview user cannot claim a ticket" do
    sign_in @preview
    patch claim_ticket_path(@ticket)
    assert_response :redirect
    assert_nil @ticket.reload.assigned_to_id
  end

  test "preview user cannot close a ticket" do
    sign_in @preview
    patch close_ticket_path(@ticket), params: { comment: { content: "closing" } }
    assert_response :redirect
    assert_not_equal "Closed", @ticket.reload.status
  end

  test "preview user cannot comment on a ticket" do
    sign_in @preview
    assert_no_difference -> { Comment.count } do
      post ticket_comments_path(@ticket), params: { comment: { content: "hi" } }
    end
    assert_response :redirect
  end

  test "preview user cannot modify their own account" do
    sign_in @preview
    patch user_registration_path, params: { user: { first_name: "Hacked" } }
    assert_response :redirect
    assert_not_equal "Hacked", @preview.reload.first_name
  end

  test "preview user cannot terminate a user" do
    sign_in @preview
    assert_no_difference -> { User.count }, -> { TerminatedUser.count } do
      delete admin_user_path(@staff), params: { termination: { reason: "nope" } }
    end
    assert_response :redirect
  end

  # --- PII masking -------------------------------------------------------------------
  test "admin dashboard hides real user emails in preview" do
    sign_in @preview
    get admin_dashboard_path
    assert_response :success
    assert_no_match @staff.email, response.body
    assert_match "hidden@preview.local", response.body
  end

  test "admin user detail page hides real PII in preview" do
    sign_in @preview
    get admin_user_path(@staff)
    assert_response :success
    assert_no_match @staff.email, response.body
    assert_no_match @staff.display_name, response.body
    assert_no_match "remove-user-dialog", response.body
  end

  test "terminated users page hides real PII in preview" do
    sign_in @preview
    TerminatedUser.create!(
      original_user_id: 999, email: "former@example.com",
      first_name: "Former", last_name: "Employee", role: "staff",
      reason: "Resigned.", terminated_by_name: "Zoe Clarke"
    )
    get admin_terminated_users_path
    assert_response :success
    assert_no_match "former@example.com", response.body
    assert_no_match "Former Employee", response.body
    assert_no_match "Zoe Clarke", response.body
  end
end
