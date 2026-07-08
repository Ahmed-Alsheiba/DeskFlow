require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @admin   = users(:admin)
    @manager = users(:two)
    @staff   = users(:one)
    @staff2  = users(:three)
    @preview = users(:preview)
  end

  # --- removable_by? -----------------------------------------------------------------
  test "admin can remove staff and managers" do
    assert @staff.removable_by?(@admin)
    assert @manager.removable_by?(@admin)
  end

  test "admins can never be removed" do
    other_admin = User.new(role: "admin")
    assert_not @admin.removable_by?(other_admin)
    assert_not @admin.removable_by?(@manager)
    assert_not @admin.removable_by?(@staff)
  end

  test "manager can remove staff but not managers or admins" do
    assert @staff.removable_by?(@manager)
    other_manager = User.new(role: "manager")
    assert_not @manager.removable_by?(other_manager)
    assert_not @admin.removable_by?(@manager)
  end

  test "staff cannot remove anyone" do
    assert_not @staff2.removable_by?(@staff)
    assert_not @manager.removable_by?(@staff)
  end

  test "nobody can remove themselves" do
    assert_not @admin.removable_by?(@admin)
    assert_not @manager.removable_by?(@manager)
    assert_not @staff.removable_by?(@staff)
  end

  test "the preview account can never be removed and can never remove" do
    assert_not @preview.removable_by?(@admin)
    assert_not @staff.removable_by?(@preview)
  end

  test "a nil actor cannot remove" do
    assert_not @staff.removable_by?(nil)
  end

  # --- terminate! --------------------------------------------------------------------
  test "terminate! archives counts, reverts open assigned tickets, and destroys the user" do
    assigned_open   = tickets(:assigned_open)   # In Progress, assignee: staff
    assigned_closed = tickets(:assigned_closed) # Closed, assignee: staff
    submitted       = tickets(:one)             # submitted by staff
    comment         = comments(:one)            # authored by staff

    # Lowercase status proves the closed-check is case-insensitive.
    lowercase_closed = Ticket.create!(
      title: "Legacy record", description: "Closed with lowercase status.",
      category: "Other", status: "closed", priority: "Low",
      assignee: @staff, submitter: @manager
    )

    archived = nil
    assert_difference -> { User.count } => -1, -> { TerminatedUser.count } => 1 do
      archived = @staff.terminate!(by: @admin, reason: "Violation of policy")
    end

    assert_equal @staff.id, archived.original_user_id
    assert_equal @staff.email, archived.email
    assert_equal @staff.first_name, archived.first_name
    assert_equal @staff.last_name, archived.last_name
    assert_equal "staff", archived.role
    assert_equal 1, archived.submitted_tickets_count
    assert_equal 3, archived.assigned_tickets_count
    assert_equal 2, archived.solved_tickets_count
    assert_equal 1, archived.comments_count
    assert_equal @admin.id, archived.terminated_by_id
    assert_equal @admin.display_name, archived.terminated_by_name

    # Non-closed assigned ticket returns to the pool.
    assigned_open.reload
    assert_equal "Open", assigned_open.status
    assert_nil assigned_open.assigned_to_id
    assert_nil assigned_open.assigned_to

    # Closed assigned tickets keep their status and name snapshot; FK is nullified.
    assigned_closed.reload
    assert_equal "Closed", assigned_closed.status
    assert_nil assigned_closed.assigned_to_id
    assert_equal "Test User", assigned_closed.assigned_to
    assert_equal "closed", lowercase_closed.reload.status

    # Submitted tickets and comments survive with nullified FKs.
    assert_nil submitted.reload.submitter_id
    assert_nil comment.reload.author_id

    # Attribution back-links are stamped on every touched record (including the
    # reverted open ticket, as history), and the links match the stored counts.
    assert_equal archived.id, submitted.submitter_terminated_user_id
    assert_equal archived.id, assigned_open.assignee_terminated_user_id
    assert_equal archived.id, assigned_closed.assignee_terminated_user_id
    assert_equal archived.id, comment.author_terminated_user_id
    assert_equal archived.submitted_tickets_count, archived.submitted_tickets.count
    assert_equal archived.assigned_tickets_count, archived.assigned_tickets.count
    assert_equal archived.comments_count, archived.comments.count
  end

  # --- suspendable_by? ---------------------------------------------------------------
  test "suspendable_by? mirrors the removal tiers" do
    assert @staff.suspendable_by?(@admin)
    assert @manager.suspendable_by?(@admin)
    assert @staff.suspendable_by?(@manager)
    assert_not @manager.suspendable_by?(@manager) # not managers/self
    assert_not @admin.suspendable_by?(@manager)   # not admins
    assert_not @staff.suspendable_by?(@staff)     # not self
    assert_not @staff2.suspendable_by?(@staff)    # staff can't act
    assert_not @preview.suspendable_by?(@admin)   # never the demo account
    assert_not @staff.suspendable_by?(nil)
  end

  # --- suspend! / reinstate! ---------------------------------------------------------
  test "suspend! blocks authentication and leaves assigned tickets untouched" do
    assigned_open = tickets(:assigned_open) # In Progress, assignee: staff

    @staff.suspend!(by: @admin, reason: "Under investigation")

    assert @staff.suspended?
    assert_not @staff.active_for_authentication?
    assert_equal :suspended, @staff.inactive_message
    assert_equal @admin.id, @staff.suspended_by_id
    assert_equal "Under investigation", @staff.suspension_reason

    # Tickets stay put — suspension is temporary.
    assigned_open.reload
    assert_equal "In Progress", assigned_open.status
    assert_equal @staff.id, assigned_open.assigned_to_id
  end

  test "reinstate! clears suspension and restores authentication" do
    @staff.suspend!(by: @admin, reason: "temp")
    @staff.reinstate!(by: @manager)

    assert_not @staff.suspended?
    assert @staff.active_for_authentication?
    assert_nil @staff.suspended_at
    assert_nil @staff.suspended_by_id
    assert_nil @staff.suspension_reason
  end

  test "suspend! and reinstate! raise for a non-permitted actor" do
    assert_raises(ArgumentError) { @staff2.suspend!(by: @staff, reason: "nope") }
    assert_not @staff2.reload.suspended?

    @staff2.update!(suspended_at: Time.current)
    assert_raises(ArgumentError) { @staff2.reinstate!(by: @staff) }
    assert @staff2.reload.suspended?
  end

  test "assignable scope excludes preview and suspended users" do
    @staff.update!(suspended_at: Time.current)
    assignable = User.assignable
    assert_includes assignable, @manager
    assert_not_includes assignable, @staff
    assert_not_includes assignable, @preview
  end

  test "terminate! raises for a non-permitted actor and changes nothing" do
    assert_no_difference -> { User.count }, -> { TerminatedUser.count } do
      assert_raises(ArgumentError) { @staff2.terminate!(by: @staff, reason: "nope") }
    end
    assert User.exists?(@staff2.id)
  end

  test "terminate! rolls back entirely when the archive row is invalid" do
    assigned_open = tickets(:assigned_open)
    assert_no_difference -> { User.count }, -> { TerminatedUser.count } do
      assert_raises(ActiveRecord::RecordInvalid) { @staff.terminate!(by: @admin, reason: "") }
    end
    assert User.exists?(@staff.id)
    assert_equal "In Progress", assigned_open.reload.status
  end
end
