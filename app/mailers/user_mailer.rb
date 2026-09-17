class UserMailer < ApplicationMailer
  # Takes the TerminatedUser archive row — the User row is already destroyed.
  # The termination report is deliberately not included; it stays internal.
  def removed
    @terminated_user = params[:terminated_user]
    mail to: @terminated_user.email, subject: "Your DeskFlow account has been removed"
  end
end
