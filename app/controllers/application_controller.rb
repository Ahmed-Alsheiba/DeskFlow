class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  include Pagy::Method

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :block_preview_writes

  # Controller/actions a preview (read-only) user is still allowed to POST/PATCH/DELETE.
  # Only leaving the demo (signing out) is permitted; everything else mutating is denied.
  PREVIEW_ALLOWED_NON_GET = {
    "devise/sessions"   => %w[destroy], # "Exit Preview" sign-out
    "preview_sessions"  => %w[destroy]  # "Sign up / Login" exits preview then forwards
  }.freeze

  private

  # Read-only demo session helper. nil-safe so it works for signed-out visitors too.
  def preview_mode?
    current_user&.preview?
  end
  helper_method :preview_mode?

  # Server-side defense-in-depth: a preview account can never mutate data, regardless of
  # which buttons/forms a view happens to render. Blocks create/update/claim/close,
  # comment creation, and Devise account update/delete. Sign-out is the only allowed
  # non-GET so the visitor can leave preview mode.
  def block_preview_writes
    return unless preview_mode?
    return if request.get? || request.head?
    return if PREVIEW_ALLOWED_NON_GET[params[:controller]]&.include?(params[:action])

    respond_to do |format|
      format.html { redirect_back fallback_location: tickets_path, alert: "Preview mode — this is a read-only demo. Sign up to make changes." }
      format.any  { head :forbidden }
    end
  end

  def configure_permitted_parameters
    keys = [ :first_name, :last_name, :job_title, :sector ]
    devise_parameter_sanitizer.permit(:sign_up, keys: keys)
    devise_parameter_sanitizer.permit(:account_update, keys: keys)
  end

  def require_admin_or_manager!
    return if current_user&.admin? || current_user&.manager? || current_user&.preview?

    redirect_to root_path, alert: "You are not authorized to access that page."
  end

  # True role-based check (excludes preview), for surfacing manager-only UI such
  # as the suspended-assignee flag on a ticket.
  def admin_or_manager?
    current_user&.admin? || current_user&.manager?
  end

  def can_edit_ticket?(ticket)
    return false unless user_signed_in?
    return false if current_user.preview?
    current_user.admin? || current_user.manager? || current_user == ticket.submitter || current_user == ticket.assignee
  end

  def can_comment_ticket?(ticket)
    can_edit_ticket?(ticket)
  end

  def can_self_assign_ticket?(ticket)
    return false unless user_signed_in?
    return false if current_user.preview?
    return false if ticket.status.to_s.strip.casecmp("closed").zero? # closed tickets are terminal

    ticket.assigned_to_id.nil?
  end

  helper_method :can_edit_ticket?, :can_comment_ticket?, :can_self_assign_ticket?, :admin_or_manager?
end
