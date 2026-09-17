class Users::RegistrationsController < Devise::RegistrationsController
  # A wrong "current password" on the account page counts toward the sign-in
  # lockout; hitting the limit ends the session right away.
  def update
    super do |user|
      if user.access_locked?
        sign_out user
        return redirect_to new_user_session_path, alert: t("devise.failure.locked")
      end
    end
  end

  # Self-service account deletion is disabled; removal is admin/manager-driven
  # via Admin::UsersController#destroy (termination flow with archival).
  def destroy
    redirect_to edit_user_registration_path,
      alert: "Account deletion is disabled. Please contact an administrator."
  end

  protected

  def update_resource(resource, params)
    resource.confirm_password(params[:current_password].to_s) # counts/clears attempts
    super
  end
end
