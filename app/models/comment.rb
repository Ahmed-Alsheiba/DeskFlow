class Comment < ApplicationRecord
  belongs_to :ticket
  belongs_to :author, class_name: "User", optional: true

  validates :content, presence: true
end
