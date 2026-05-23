require "test_helper"

class TicketTest < ActiveSupport::TestCase
  def build_user(email:)
    User.create!(
      email: email,
      password: "password",
      password_confirmation: "password",
      first_name: "Test",
      last_name: "User",
      role: "staff",
      sector: "IT/Operations",
      job_title: "Technician"
    )
  end

  test "assigning an open ticket sets status to in progress" do
    submitter = build_user(email: "submitter@example.com")
    assignee = build_user(email: "assignee@example.com")

    ticket = Ticket.create!(
      title: "Printer offline",
      description: "Offline",
      status: "Open",
      category: "Hardware",
      priority: "Medium",
      location: "Office",
      submitter: submitter
    )

    ticket.update!(assigned_to_id: assignee.id)

    assert_equal "In Progress", ticket.status
  end

  test "creating a ticket assigned to someone sets status to in progress" do
    submitter = build_user(email: "submitter2@example.com")
    assignee = build_user(email: "assignee2@example.com")

    ticket = Ticket.create!(
      title: "Network issue",
      description: "Slow",
      status: "Open",
      category: "Network",
      priority: "High",
      location: "Lobby",
      submitter: submitter,
      assigned_to_id: assignee.id
    )

    assert_equal "In Progress", ticket.status
  end
end
