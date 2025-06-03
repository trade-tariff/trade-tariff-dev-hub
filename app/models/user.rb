class User < ApplicationRecord
  has_paper_trail

  belongs_to :organisation
  has_many :sessions, dependent: :destroy

  delegate :status, :application_reference, to: :organisation

  def self.from_profile!(government_gateway_profile)
    organisation = Organisation.from_profile!(government_gateway_profile)

    find_or_initialize_by(
      organisation_id: organisation.id,
      user_id: government_gateway_profile["sub"],
    ).tap do |user|
      if user.new_record?
        user.email_address = government_gateway_profile["email"]
        user.save!
      end
    end
  end
end
