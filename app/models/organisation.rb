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

  # rubocop:disable Rails/UniqueValidationWithoutIndex
  # Uniqueness validation is enforced at application level only
  validates :organisation_name, presence: true, uniqueness: true
  # rubocop:enable Rails/UniqueValidationWithoutIndex

  class << self
    def admin_organisation
      admin_role = Role.find_by(name: "admin")
      Organisation.joins(:roles).where(roles: { id: admin_role.id }).first
    end

    def find_or_associate_implicit_organisation_to(user)
      return if user.organisation.present?

      invitation = Invitation.find_by(
        invitee_email: user.email_address,
        status: :pending,
      )

      unless invitation
        raise InvitationRequiredError, "No pending invitation found for #{user.email_address}"
      end

      User.transaction do
        user.organisation = invitation.organisation
        invitation.accepted!
        user.save!
      end
    end
  end

  class InvitationRequiredError < StandardError
  end

  def admin?
    has_role?("admin")
  end

  def implicitly_created?
    role_names = roles.pluck(:name)
    role_names.empty? || role_names == ["trade_tariff:full"]
  end

  def fpo?
    has_role?("fpo:full")
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
