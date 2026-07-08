module Admin
  class UsersController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin_or_manager!
    before_action :set_user

    def show
      @claimed_tickets = @user.assigned_tickets.order(created_at: :desc).to_a
      @solved_count = @claimed_tickets.count { |t| t.status.to_s.strip.casecmp("closed").zero? }
      @submitted_tickets = @user.submitted_tickets.order(created_at: :desc).to_a
      @comments_count = @user.comments.count
      # Best-effort name of who suspended them (nil if that account is gone).
      @suspended_by = User.find_by(id: @user.suspended_by_id) if @user.suspended?
    end

    def destroy
      unless @user.removable_by?(current_user)
        return redirect_to admin_user_path(@user), alert: "You are not authorized to remove this user."
      end

      reason = params.dig(:termination, :reason).to_s.strip
      if reason.blank?
        return redirect_to admin_user_path(@user), alert: "Please provide a termination report."
      end

      name = @user.display_name
      @user.terminate!(by: current_user, reason: reason)
      redirect_to admin_dashboard_path, notice: "#{name} has been removed. Their record was archived to Terminated Users."
    rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotDestroyed
      redirect_to admin_dashboard_path, alert: "Unable to remove that user. They may have already been removed."
    end

    def suspend
      unless @user.suspendable_by?(current_user)
        return redirect_to admin_user_path(@user), alert: "You are not authorized to suspend this user."
      end

      reason = params.dig(:suspension, :reason).to_s.strip
      if reason.blank?
        return redirect_to admin_user_path(@user), alert: "Please provide a reason for the suspension."
      end

      @user.suspend!(by: current_user, reason: reason)
      redirect_to admin_user_path(@user), notice: "#{@user.display_name} has been suspended."
    rescue ActiveRecord::RecordInvalid, ArgumentError
      redirect_to admin_user_path(@user), alert: "Unable to suspend that user."
    end

    def reinstate
      unless @user.suspendable_by?(current_user)
        return redirect_to admin_user_path(@user), alert: "You are not authorized to reinstate this user."
      end

      @user.reinstate!(by: current_user)
      redirect_to admin_user_path(@user), notice: "#{@user.display_name} has been reinstated."
    rescue ActiveRecord::RecordInvalid, ArgumentError
      redirect_to admin_user_path(@user), alert: "Unable to reinstate that user."
    end

    private

    # The preview demo account is invisible in the admin area, mirroring the
    # dashboard's User.where.not(role: "preview") scope.
    def set_user
      @user = User.where.not(role: "preview").find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_dashboard_path, alert: "That user no longer exists."
    end
  end
end
