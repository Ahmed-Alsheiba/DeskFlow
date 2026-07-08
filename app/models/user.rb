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

  # Tiered removal: managers remove staff only; admins remove staff + managers.
  # Nobody removes admins, themselves, or the preview demo account.
  def removable_by?(actor)
    return false if actor.nil? || actor == self
    return false if admin? || preview?
    return true if actor.admin?

    actor.manager? && staff?
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
      # Non-closed assigned tickets go back to the pool; the denormalized
      # assigned_to name is cleared so they show as "Unassigned". update_all
      # skips callbacks, so updated_at is set manually.
      assigned_tickets.where.not(closed)
        .update_all(status: "Open", assigned_to_id: nil, assigned_to: nil, updated_at: Time.current)
      # destroy! last: dependent: :nullify clears the remaining FKs (submitted
      # tickets, closed assigned tickets, comments) required by the DB.
      destroy!
      archived
    end
  end
end
