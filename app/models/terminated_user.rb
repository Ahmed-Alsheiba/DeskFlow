class TerminatedUser < ApplicationRecord
  # Archive row for a removed user (see User#terminate!). Holds only snapshots —
  # both original_user_id and terminated_by_id point at rows that may no longer
  # exist, so there are no associations.
  validates :email, presence: true
  validates :role, presence: true
  validates :reason, presence: true
  validates :terminated_by_name, presence: true

  def display_name
    [ first_name, last_name ].compact_blank.join(" ").presence || email
  end
end
