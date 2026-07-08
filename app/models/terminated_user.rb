class TerminatedUser < ApplicationRecord
  # Archive row for a removed user (see User#terminate!). Identity is snapshot-only
  # (original_user_id and terminated_by_id point at rows that may no longer exist),
  # but the records the user touched keep durable back-links stamped at termination.
  has_many :submitted_tickets, class_name: "Ticket", foreign_key: "submitter_terminated_user_id", dependent: :nullify
  has_many :assigned_tickets, class_name: "Ticket", foreign_key: "assignee_terminated_user_id", dependent: :nullify
  has_many :comments, class_name: "Comment", foreign_key: "author_terminated_user_id", dependent: :nullify

  validates :email, presence: true
  validates :role, presence: true
  validates :reason, presence: true
  validates :terminated_by_name, presence: true

  def display_name
    [ first_name, last_name ].compact_blank.join(" ").presence || email
  end
end
