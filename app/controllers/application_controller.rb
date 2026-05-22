class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  include Pagy::Method

  private

  def require_admin_or_manager!
    return if current_user&.admin? || current_user&.manager?

    redirect_to root_path, alert: "You are not authorized to access that page."
  end
end
