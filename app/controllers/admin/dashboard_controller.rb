module Admin
  class DashboardController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin_or_manager!

    def index
      @users = User.where.not(role: "preview").order(:first_name, :last_name, :email).to_a
      @users_by_id = @users.index_by(&:id)
      @tickets = Ticket.order(created_at: :desc).to_a

      @tickets_by_status = Ticket.group(:status).count
      weekday_order = Date::DAYNAMES.rotate(1)
      @tickets_reported = weekday_order.index_with { 0 }
      @tickets.each do |ticket|
        day_name = ticket.created_at.in_time_zone.strftime("%A")
        @tickets_reported[day_name] += 1
      end
      @tickets_by_category = Ticket.group(:category).count

      if preview_mode?
        # Mask real assignee names in the chart labels for the read-only demo.
        @tickets_by_assignee = Ticket.group(:assigned_to_id).count
          .transform_keys { |id| id ? "User ##{id}" : "Unassigned" }
      else
        assignee_label_sql = "COALESCE(NULLIF(TRIM(users.first_name || ' ' || users.last_name), ''), 'Unassigned')"
        @tickets_by_assignee = Ticket.left_outer_joins(:assignee).group(Arel.sql(assignee_label_sql)).count
      end
    end
  end
end
