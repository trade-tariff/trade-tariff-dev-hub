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
#  uk_acs_reference      :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  status                :integer
#

class Organisation < ApplicationRecord
  has_paper_trail

  has_many :users, dependent: :destroy
  has_many :invitations, dependent: :destroy
  has_many :api_keys, dependent: :destroy
  has_and_belongs_to_many :roles

  validates :organisation_name, presence: true

  class << self
    def find_or_associate_implicit_organisation_to(user)
      if user.organisation.blank?
        invitation = Invitation.find_by(invitee_email: user.email_address)

        if invitation.present?
          user.organisation = invitation.organisation
          invitation.accepted!
          user.save!
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
end
