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
  TRADE_TARIFF_ROLE_NAME = "trade_tariff:full".freeze
  FPO_ROLE_NAME = "fpo:full".freeze
  SERVICE_ROLE_NAMES = [TRADE_TARIFF_ROLE_NAME, FPO_ROLE_NAME].freeze

  validates :name, presence: true, uniqueness: true
  validates :description, presence: true

  has_and_belongs_to_many :organisations
  has_paper_trail

  scope :service_roles, -> { where(name: SERVICE_ROLE_NAMES) }
  scope :not_assigned_to, ->(organisation) { where.not(id: organisation.roles.select(:id)) }

  def self.available_service_roles_for(organisation)
    service_roles.not_assigned_to(organisation).order(:name)
  end

  def admin?
    name == ADMIN_ROLE_NAME
  end
end
