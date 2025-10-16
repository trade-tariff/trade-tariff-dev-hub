# == Schema Information
#
# Table name: users
#
#  id              :uuid             not null, primary key
#  organisation_id :uuid             not null
#  email_address   :string
#  user_id         :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_email_address    (email_address) UNIQUE
#  index_users_on_organisation_id  (organisation_id)
#

class User < ApplicationRecord
  has_paper_trail

  belongs_to :organisation
  has_many :sessions, dependent: :destroy

  validates :email_address, presence: true, uniqueness: true

  class << self
    def from_passwordless_payload!(token)
      return dummy_user! if Rails.env.development?

      user_id = token["sub"]

      user = User.find_or_initialize_by(email_address: token["email"])

      if !user.new_record? && user.user_id != user_id
        Rails.logger.warn("User ID mismatch for email #{user.email_address}: existing user_id=#{user.user_id}, new user_id=#{user_id}. Updating to new user_id.")
      end

      user.user_id = user_id

      Organisation.find_or_associate_implicit_organisation_to(user) if user.organisation.blank?

      user.save!

      user
    end

    def dummy_user!
      User.find_or_initialize_by(user_id: "dummy_user", email_address: "dummy@user.com").tap do |user|
        Organisation.find_or_associate_implicit_organisation_to(user)
        user.save!
      end
    end
  end

  delegate :admin?, to: :organisation
end
