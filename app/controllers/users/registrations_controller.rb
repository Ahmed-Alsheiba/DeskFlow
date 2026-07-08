class Users::RegistrationsController < Devise::RegistrationsController
  # Self-service account deletion is disabled; removal is admin/manager-driven
  # via Admin::UsersController#destroy (termination flow with archival).
  def destroy
    redirect_to edit_user_registration_path,
      alert: "Account deletion is disabled. Please contact an administrator."
  end
end
