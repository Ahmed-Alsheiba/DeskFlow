class Ticket < ApplicationRecord
  has_many :comments, dependent: :destroy
  belongs_to :submitter, class_name: "User", optional: true
  belongs_to :assignee, class_name: "User", foreign_key: :assigned_to_id, optional: true
  # Archive back-links, stamped by User#terminate! when the submitter/assignee is removed.
  belongs_to :submitter_terminated_user, class_name: "TerminatedUser", optional: true
  belongs_to :assignee_terminated_user, class_name: "TerminatedUser", optional: true

  before_validation :set_in_progress_on_assignment

  STATUSES = [ "Open", "In Progress", "Closed" ].freeze
  PRIORITIES = [ "Low", "Medium", "High" ].freeze
  CATEGORIES = [ "Hardware", "Software", "Network", "POS", "PMS", "Other" ].freeze

  # Scopes for filtering
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :by_priority, ->(priority) { where(priority: priority) if priority.present? }
  scope :by_category, ->(category) { where(category: category) if category.present? }
  scope :search, ->(query) { where("title ILIKE ? OR description ILIKE ?", "%#{query}%", "%#{query}%") if query.present? }

  def self.status_options = STATUSES
  def self.priority_options = PRIORITIES
  def self.category_options = CATEGORIES

  private

  def set_in_progress_on_assignment
    return unless assigned_to_id.present?
    return unless new_record? || will_save_change_to_assigned_to_id?
    return unless status.blank? || status.to_s.strip.casecmp("open").zero?

    self.status = "In Progress"
  end
end
