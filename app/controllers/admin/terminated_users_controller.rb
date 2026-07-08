module Admin
  class TerminatedUsersController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin_or_manager!

    def index
      @terminated_users = TerminatedUser.order(created_at: :desc).to_a
    end

    def show
      @terminated_user = TerminatedUser.find(params[:id])
      @submitted_tickets = @terminated_user.submitted_tickets.order(created_at: :desc).to_a
      @assigned_tickets = @terminated_user.assigned_tickets.order(created_at: :desc).to_a
      @comments = @terminated_user.comments.includes(:ticket).order(created_at: :desc).to_a
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_terminated_users_path, alert: "That record no longer exists."
    end
  end
end
