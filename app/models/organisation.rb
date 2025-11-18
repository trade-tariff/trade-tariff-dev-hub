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
  has_many :ott_keys, dependent: :destroy
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
            organisation.assign_role!("ott:full")
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
    if role_name.start_with?("ott") && ott_keys.active.exists?
      :ott_keys
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

  def ott_access?
    has_role?("ott:full")
  end
end
