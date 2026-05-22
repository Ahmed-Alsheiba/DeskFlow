class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  include Pagy::Method

  private

  def require_admin_or_manager!
    return if current_user&.admin? || current_user&.manager?

    redirect_to root_path, alert: "You are not authorized to access that page."
  end

  def can_edit_ticket?(ticket)
    return false unless user_signed_in?
    current_user.admin? || current_user.manager? || current_user == ticket.submitter || current_user == ticket.assignee
  end

  def can_comment_ticket?(ticket)
    can_edit_ticket?(ticket)
  end

  def can_self_assign_ticket?(ticket)
    return false unless user_signed_in?
    ticket.assigned_to_id.nil?
  end

  helper_method :can_edit_ticket?, :can_comment_ticket?, :can_self_assign_ticket?
end
