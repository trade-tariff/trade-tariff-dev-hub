class Role < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :description, presence: true

  has_and_belongs_to_many :organisations
  has_paper_trail

  def self.role_names
    pluck(:name)
  end
end
