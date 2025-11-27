class Ticket < ApplicationRecord
  has_many :comments, dependent: :destroy
end
