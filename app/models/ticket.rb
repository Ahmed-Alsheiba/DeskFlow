class Ticket < ApplicationRecord
  has_many :comments, dependent: :destroy
  belongs_to :submitter, class_name: "User", optional: true
  belongs_to :assignee, class_name: "User", foreign_key: :assigned_to_id, optional: true

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
end
