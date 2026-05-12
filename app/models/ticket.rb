class Ticket < ApplicationRecord
  has_many :comments, dependent: :destroy

  # Scopes for filtering
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :by_priority, ->(priority) { where(priority: priority) if priority.present? }
  scope :by_category, ->(category) { where(category: category) if category.present? }
  scope :search, ->(query) { where("title ILIKE ? OR description ILIKE ?", "%#{query}%", "%#{query}%") if query.present? }
end
