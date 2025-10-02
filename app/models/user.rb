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
#  index_users_on_organisation_id              (organisation_id)
#  index_users_on_user_id_and_organisation_id  (user_id,organisation_id) UNIQUE
#

class User < ApplicationRecord
  has_paper_trail

  belongs_to :organisation
  has_many :sessions, dependent: :destroy

  class << self
    def from_passwordless_payload!(token)
      return dummy_user! if Rails.env.development?

      user = User.find_or_initialize_by(user_id: token["sub"], email_address: token["email"])

      Organisation.find_or_associate_implicit_organisation_to(user) if user.organisation.nil?

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
end
