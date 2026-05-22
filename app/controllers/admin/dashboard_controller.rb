module Admin
  class DashboardController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin_or_manager!

    def index
      @users = User.order(:first_name, :last_name, :email).to_a
      @users_by_id = @users.index_by(&:id)
      @tickets = Ticket.order(created_at: :desc).to_a
    end
  end
end
