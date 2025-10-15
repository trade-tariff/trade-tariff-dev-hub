# == Schema Information
#
# Table name: roles
#
#  id          :uuid             not null, primary key
#  name        :string           not null
#  description :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_roles_on_name  (name) UNIQUE
#

class Role < ApplicationRecord
  ADMIN_ROLE_NAME = "admin".freeze
  SERVICE_ROLE_NAMES = %w[ott:full fpo:full spimm:full].freeze

  validates :name, presence: true, uniqueness: true
  validates :description, presence: true

  has_and_belongs_to_many :organisations
  has_paper_trail

  scope :service_roles, -> { where(name: SERVICE_ROLE_NAMES) }

  def self.assignable_names
    SERVICE_ROLE_NAMES
  end

  def admin?
    name == ADMIN_ROLE_NAME
  end
end
