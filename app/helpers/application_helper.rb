module ApplicationHelper
  def user_display_name(user)
    return nil if user.blank?

    [ user.first_name, user.last_name ].compact_blank.join(" ").presence || user.email
  end
end
