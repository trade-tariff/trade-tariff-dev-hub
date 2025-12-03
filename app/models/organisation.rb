# == Schema Information
#
# Table name: organisations
#
#  id                    :uuid             not null, primary key
#  organisation_id       :string
#  application_reference :string
#  description           :string
#  eori_number           :string
#  organisation_name     :string
#  status                :integer
#  uk_acs_reference      :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#

class Organisation < ApplicationRecord
  has_paper_trail

  has_many :users, dependent: :destroy
  has_many :invitations, dependent: :destroy
  has_many :api_keys, dependent: :destroy
  has_many :trade_tariff_keys, dependent: :destroy
  has_many :role_requests, dependent: :destroy
  has_and_belongs_to_many :roles

  validates :organisation_name, presence: true

  class << self
    def find_or_associate_implicit_organisation_to(user)
      if user.organisation.blank?
        invitation = Invitation.find_by(
          invitee_email: user.email_address,
          status: :pending,
        )

        if invitation.present?
          User.transaction do
            user.organisation = invitation.organisation
            invitation.accepted!
            user.save!
          end
        else
          new(organisation_name: user.email_address).tap do |organisation|
            organisation.description = "Default implicit organisation for initial user #{user.email_address}"
            organisation.save!
            organisation.assign_role!("trade_tariff:full")
            user.organisation = organisation
            user.save!
          end
        end
      end
    end
  end

  def admin?
    has_role?("admin")
  end

  def has_role?(role_name)
    roles.exists?(name: role_name)
  end

  def remove_role_block_reason(role_name)
    if role_name.start_with?("trade_tariff") && trade_tariff_keys.active.exists?
      :trade_tariff_keys
    elsif role_name.start_with?("fpo") && api_keys.active.exists?
      :active_api_keys
    end
  end

  def can_remove_role?(role_name)
    remove_role_block_reason(role_name).nil?
  end

  def assign_role!(role_name)
    role = Role.find_by!(name: role_name)

    unless roles.include?(role)
      roles << role
      save!
    end
  end

  def unassign_role!(role_name)
    role = Role.find_by!(name: role_name)

    roles.delete(role)
    save!
  end

  def fpo_access?
    has_role?("fpo:full")
  end

  def trade_tariff_access?
    has_role?("trade_tariff:full")
  end

  def available_service_roles
    assigned_service_role_ids = roles.service_roles.pluck(:id)
    Role.service_roles.where.not(id: assigned_service_role_ids).order(:name)
  end

  def pending_request_for?(role_name)
    role_requests.pending.exists?(role_name: role_name)
  end
end
