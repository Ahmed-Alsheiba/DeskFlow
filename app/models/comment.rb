class Comment < ApplicationRecord
  belongs_to :ticket
  belongs_to :author, class_name: "User", optional: true
  # Archive back-link, stamped by User#terminate! when the author is removed.
  belongs_to :author_terminated_user, class_name: "TerminatedUser", optional: true

  validates :content, presence: true
end
