class PreviewSessionsController < ApplicationController
  # Signs the visitor in as the locked-down, read-only "preview" account so they can
  # explore the app without registering. The account can never mutate data — see
  # ApplicationController#block_preview_writes and the preview-aware authorization
  # helpers in ApplicationController.
  def create
    user = User.find_by(role: "preview")

    if user
      sign_in(user)
      redirect_to tickets_path, notice: "You're exploring DeskFlow in read-only preview mode."
    else
      redirect_to root_path, alert: "Preview is unavailable right now."
    end
  end

  # Leaves preview mode and forwards to the real sign-up (or sign-in) page. Signing the
  # demo account out first avoids Devise's "You are already signed in" bounce, since its
  # registration/session pages reject authenticated users.
  def destroy
    sign_out(:user) if user_signed_in?
    redirect_to(params[:to] == "login" ? new_user_session_path : new_user_registration_path)
  end
end
