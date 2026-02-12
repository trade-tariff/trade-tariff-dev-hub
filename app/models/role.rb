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
  SERVICE_ROLE_NAMES = %w[trade_tariff:full fpo:full spimm:full].freeze

  validates :name, presence: true, uniqueness: true
  validates :description, presence: true

  has_and_belongs_to_many :organisations
  has_paper_trail

  scope :service_roles, -> { where(name: SERVICE_ROLE_NAMES) }

  def self.assignable_service_roles
    # Returns service roles available for assignment
    # Excludes spimm:full in production/staging (staging uses RAILS_ENV=production)
    roles = service_roles
    if TradeTariffDevHub.production_environment?
      spimm_role = find_by(name: "spimm:full")
      roles = roles.where.not(id: spimm_role.id) if spimm_role
    end
    roles
  end

  def self.assignable_names
    # Exclude spimm:full role in production/staging (staging uses RAILS_ENV=production)
    if TradeTariffDevHub.production_environment?
      SERVICE_ROLE_NAMES - ["spimm:full"]
    else
      SERVICE_ROLE_NAMES
    end
  end

  def admin?
    name == ADMIN_ROLE_NAME
  end
end
