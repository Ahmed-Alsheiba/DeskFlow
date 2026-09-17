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

      return unless password_confirmed?(:termination, "remove-user-dialog-#{@user.id}")

      name = @user.display_name
      archived = @user.terminate!(by: current_user, reason: reason)
      UserMailer.with(terminated_user: archived).removed.deliver_later
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

      return unless password_confirmed?(:suspension, "suspend-user-dialog-#{@user.id}")

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

    # Clears a wrong-password lockout early (it also expires on its own). Same tiers
    # as suspend; no password re-check since it only restores access.
    def unlock
      unless @user.suspendable_by?(current_user)
        return redirect_to admin_user_path(@user), alert: "You are not authorized to unlock this user."
      end

      @user.unlock_access!
      redirect_to admin_user_path(@user), notice: "#{@user.display_name} has been unlocked."
    end

    private

    # Sudo-style re-auth: a walked-away-from session can't remove or suspend anyone.
    # Wrong guesses count toward the sign-in lockout; hitting it ends the session.
    # Otherwise re-render (not redirect) so the typed reason survives a typo.
    def password_confirmed?(scope, dialog_id)
      return true if current_user.confirm_password(params.dig(scope, :password).to_s)

      if current_user.access_locked?
        sign_out current_user
        redirect_to new_user_session_path, alert: t("devise.failure.locked")
      else
        flash.now[:alert] = "Incorrect password. No changes were made."
        @reopen_dialog = dialog_id
        show
        render :show, status: :unprocessable_entity
      end
      false
    end

    # The preview demo account is invisible in the admin area, mirroring the
    # dashboard's User.where.not(role: "preview") scope.
    def set_user
      @user = User.where.not(role: "preview").find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_dashboard_path, alert: "That user no longer exists."
    end
  end
end
