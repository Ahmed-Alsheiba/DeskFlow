module ApplicationHelper
  def user_display_name(user)
    return nil if user.blank?
    return "User ##{user.id}" if preview_mode? # hide real names in the read-only demo

    [ user.first_name, user.last_name ].compact_blank.join(" ").presence || user.email
  end

  # Masked email for the read-only demo so real addresses are never exposed.
  def user_email_display(user)
    return nil if user.blank?
    return "hidden@preview.local" if preview_mode?

    user.email
  end

  # Renders a person's name, masking it in preview mode. Accepts the associated User
  # (preferred, gives a stable "User #id" pseudonym) plus an optional denormalized name
  # string fallback (e.g. ticket.submitter_name) for records whose user was deleted.
  def display_person(user, name = nil, fallback: "Unassigned")
    if preview_mode?
      return "User ##{user.id}" if user
      return "Anonymous" if name.present?
      return fallback
    end

    user_display_name(user).presence || name.presence || fallback
  end
end
