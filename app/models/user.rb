class User < ApplicationRecord
  has_paper_trail

  belongs_to :organisation
  has_many :sessions, dependent: :destroy

  delegate :status, :application_reference, to: :organisation

  class << self
    def from_profile!(government_gateway_profile)
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

    def from_passwordless_payload!(token)
      return dummy_user! if Rails.env.development?

      Rails.logger.debug("Finding or creating user from passwordless payload...")

      user = User.find_or_initialize_by(user_id: token["sub"], email_address: token["email"])

      Rails.logger.debug("User found or initialized: #{user.inspect}")
      Rails.logger.debug("User is new record: #{user.new_record?}")

      Organisation.find_or_associate_implicit_organisation_to(user) if user.organisation.nil?

      user.save!

      user
    end

  private

    def dummy_user!
      Rails.logger.debug("Creating or finding dummy user in development environment")
      User.find_or_create_by!(user_id: "dummy_user", email_address: "dummy@user.com").tap do |user|
        Organisation.find_or_associate_implicit_organisation_to(user)
      end
    end
  end
end
