require "test_helper"

class TicketControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @staff   = users(:one)
    @manager = users(:two)
    @open_unassigned   = tickets(:one)                 # Open, no assignee
    @closed_unassigned = tickets(:closed_unassigned)   # Closed, no assignee
    @suspended_ticket  = tickets(:assigned_to_suspended)
  end

  # --- claim guard -------------------------------------------------------------------
  test "an open unassigned ticket can be claimed" do
    sign_in @staff
    patch claim_ticket_path(@open_unassigned)
    assert_redirected_to @open_unassigned
    assert_equal @staff.id, @open_unassigned.reload.assigned_to_id
  end

  test "a closed ticket cannot be claimed" do
    sign_in @staff
    patch claim_ticket_path(@closed_unassigned)
    assert_redirected_to @closed_unassigned
    assert_nil @closed_unassigned.reload.assigned_to_id
    assert_equal "This ticket is closed and can't be claimed.", flash[:alert]
  end

  test "the Claim button is hidden for closed tickets and shown for open ones" do
    sign_in @staff
    get ticket_path(@open_unassigned)
    assert_match "Claim Ticket", response.body
    get ticket_path(@closed_unassigned)
    assert_no_match "Claim Ticket", response.body
  end

  # --- suspended-assignee flag -------------------------------------------------------
  test "a manager sees the suspended-assignee flag" do
    sign_in @manager
    get ticket_path(@suspended_ticket)
    assert_response :success
    assert_match "Suspended", response.body
    assert_match "reassign it if it's time-sensitive", response.body
  end

  test "plain staff do not see the suspended-assignee flag" do
    sign_in @staff
    get ticket_path(@suspended_ticket)
    assert_response :success
    assert_no_match "reassign it if it's time-sensitive", response.body
  end

  # --- edit form preserves a suspended current assignee ------------------------------
  test "editing keeps a suspended assignee selectable and does not drop them" do
    sign_in @manager
    get edit_ticket_path(@suspended_ticket)
    assert_response :success
    assert_match users(:suspended).display_name, response.body # still an option

    patch ticket_path(@suspended_ticket), params: { ticket: { priority: "Low" } }
    @suspended_ticket.reload
    assert_equal "Low", @suspended_ticket.priority
    assert_equal users(:suspended).id, @suspended_ticket.assigned_to_id # not unassigned
  end
end
