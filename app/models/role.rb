class Role < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :description, presence: true

  has_and_belongs_to_many :organisations
  has_paper_trail
end
