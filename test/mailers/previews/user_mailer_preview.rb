# Preview at http://localhost:3000/rails/mailers/user_mailer/removed
class UserMailerPreview < ActionMailer::Preview
  def removed
    UserMailer.with(terminated_user: TerminatedUser.new(email: "jane@example.com", first_name: "Jane", last_name: "Doe")).removed
  end
end
