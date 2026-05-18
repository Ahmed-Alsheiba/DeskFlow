class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Roles
  ROLES = [ "admin", "manager", "staff" ].freeze

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
end
