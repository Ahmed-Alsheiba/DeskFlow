module Admin
  class TerminatedUsersController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin_or_manager!

    def index
      @terminated_users = TerminatedUser.order(created_at: :desc).to_a
    end
  end
end
