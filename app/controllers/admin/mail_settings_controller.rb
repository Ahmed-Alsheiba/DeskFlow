module Admin
  # Edit the app's SMTP login from the web, and send a one-off test email to confirm it —
  # no redeploy, no `credentials:edit`. Backed by the MailSetting singleton; the password is
  # encrypted at rest. Admin-only: whoever controls SMTP can intercept password-reset mail.
  class MailSettingsController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin!
    before_action :set_setting

    def edit
    end

    def update
      unless password_confirmed?(params[:current_password])
        return if performed? # locked out — already redirected to sign-in

        @setting.assign_attributes(mail_setting_params.except(:password))
        return render :edit, status: :unprocessable_entity
      end

      if @setting.update(mail_setting_params)
        redirect_to edit_admin_mail_settings_path, notice: "Mail settings saved."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # Prove the settings work end to end — using the values currently IN THE FORM, not the
    # last saved ones, so you validate before committing. Assigns to a record that is never
    # saved, delivers synchronously (you're waiting on the result), and returns JSON the form
    # renders inline; any SMTP failure comes back as a message rather than a 500.
    def test
      @setting.assign_attributes(mail_setting_params) # transient — not saved

      unless @setting.configured?
        return render json: { ok: false, message: "Fill in the SMTP host, username and password, then test." }
      end

      MailTestMailer.test_email(to: current_user.email, from: @setting.mail_from,
                                settings: @setting.smtp_settings).deliver_now
      render json: { ok: true, message: "Test email sent to #{current_user.email} — check your inbox." }
    rescue StandardError => e
      render json: { ok: false, message: "Couldn't send: #{e.message}" }
    end

    private

    def require_admin!
      return if current_user&.admin?

      redirect_to root_path, alert: "You are not authorized to access that page."
    end

    def set_setting
      @setting = MailSetting.current
    end

    def mail_setting_params
      permitted = params.require(:mail_setting).permit(
        :enabled, :address, :port, :user_name, :password, :from_address
      )
      # A blank password field means "keep the stored one" — never overwrite the secret
      # with nothing.
      permitted.delete(:password) if permitted[:password].blank?
      permitted
    end
  end
end
