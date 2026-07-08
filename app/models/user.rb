class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Roles
  # "preview" is a locked-down, read-only demo account (see PreviewSessionsController
  # and ApplicationController#block_preview_writes). It can browse but never write.
  ROLES = [ "admin", "manager", "staff", "preview" ].freeze

  # Associations
  has_many :submitted_tickets, class_name: "Ticket", foreign_key: "submitter_id", dependent: :nullify
  has_many :assigned_tickets, class_name: "Ticket", foreign_key: "assigned_to_id", dependent: :nullify
  has_many :comments, foreign_key: "author_id", dependent: :nullify

  # Validations
  validates :role, presence: true, inclusion: { in: ROLES }
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :sector, presence: true
  validates :job_title, presence: true

  # Scopes
  scope :admins, -> { where(role: "admin") }
  scope :managers, -> { where(role: "manager") }
  scope :staff, -> { where(role: "staff") }
  # Real users who can currently take on ticket work (excludes the demo account
  # and anyone suspended).
  scope :assignable, -> { where.not(role: "preview").where(suspended_at: nil) }

  # Helpers
  def admin?
    role == "admin"
  end

  def manager?
    role == "manager"
  end

  def staff?
    role == "staff"
  end

  def preview?
    role == "preview"
  end

  def display_name
    [ first_name, last_name ].compact_blank.join(" ").presence || email
  end

  def suspended?
    suspended_at.present?
  end

  # Devise checks this on every request (see devise/hooks/activatable.rb), so a
  # suspended user is blocked from signing in AND has any live session ended on
  # their next request.
  def active_for_authentication?
    super && !suspended?
  end

  def inactive_message
    suspended? ? :suspended : super
  end

  # Removal and suspension share the same tiers: managers act on staff only;
  # admins act on staff + managers. Nobody acts on admins, themselves, or the
  # preview demo account.
  def removable_by?(actor)
    manageable_by?(actor)
  end

  def suspendable_by?(actor)
    manageable_by?(actor)
  end

  # Suspends the account (reversible). Open tickets deliberately stay assigned —
  # suspension is temporary, so the user resumes them on reinstatement.
  def suspend!(by:, reason:)
    raise ArgumentError, "not permitted to suspend #{display_name}" unless suspendable_by?(by)

    update!(suspended_at: Time.current, suspended_by_id: by.id, suspension_reason: reason)
  end

  def reinstate!(by:)
    raise ArgumentError, "not permitted to reinstate #{display_name}" unless suspendable_by?(by)

    update!(suspended_at: nil, suspended_by_id: nil, suspension_reason: nil)
  end

  # Archives this user to terminated_users, returns their non-closed assigned
  # tickets to the pool, and destroys the row — atomically. Returns the
  # TerminatedUser record.
  def terminate!(by:, reason:)
    raise ArgumentError, "#{by&.display_name || 'actor'} is not permitted to remove #{display_name}" unless removable_by?(by)

    closed = "LOWER(TRIM(status)) = 'closed'"
    transaction do
      archived = TerminatedUser.create!(
        original_user_id: id,
        email: email,
        first_name: first_name,
        last_name: last_name,
        role: role,
        job_title: job_title,
        sector: sector,
        # Counts must be captured before the revert below clears assigned_to_id.
        submitted_tickets_count: submitted_tickets.count,
        assigned_tickets_count: assigned_tickets.count,
        solved_tickets_count: assigned_tickets.where(closed).count,
        comments_count: comments.count,
        reason: reason,
        terminated_by_id: by.id,
        terminated_by_name: by.display_name
      )
      # Stamp durable back-links to the archive on every one of the user's
      # records (before destroy! nullifies the user FKs) so the archive can list
      # exactly what they touched. Stamping all assigned tickets — not just the
      # closed ones — keeps the count equal to archived.assigned_tickets.count.
      submitted_tickets.update_all(submitter_terminated_user_id: archived.id, updated_at: Time.current)
      assigned_tickets.update_all(assignee_terminated_user_id: archived.id, updated_at: Time.current)
      comments.update_all(author_terminated_user_id: archived.id, updated_at: Time.current)
      # Non-closed assigned tickets go back to the pool; the denormalized
      # assigned_to name is cleared so they show as "Unassigned" (the archive
      # link above is retained as history). update_all skips callbacks, so
      # updated_at is set manually.
      assigned_tickets.where.not(closed)
        .update_all(status: "Open", assigned_to_id: nil, assigned_to: nil, updated_at: Time.current)
      # destroy! last: dependent: :nullify clears the remaining FKs (submitted
      # tickets, closed assigned tickets, comments) required by the DB.
      destroy!
      archived
    end
  end

  private

  def manageable_by?(actor)
    return false if actor.nil? || actor == self
    return false if admin? || preview?
    return true if actor.admin?

    actor.manager? && staff?
  end
end
