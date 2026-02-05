# == Schema Information
#
# Table name: sessions
#
#  id                      :uuid             not null, primary key
#  token                   :string           not null
#  user_id                 :uuid             not null
#  expires_at              :datetime
#  raw_info                :jsonb
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  id_token                :text             not null
#  assumed_organisation_id :uuid
#
# Indexes
#
#  index_sessions_on_assumed_organisation_id  (assumed_organisation_id)
#  index_sessions_on_token                    (token) UNIQUE
#  index_sessions_on_user_id                  (user_id)
#

class Session < ApplicationRecord
  belongs_to :user
  belongs_to :assumed_organisation, class_name: "Organisation", optional: true

  validates :token, presence: true, uniqueness: true
  validates :id_token, presence: true

  def token=(value)
    super(value.present? ? self.class.digest(value) : value)
  end

  def self.digest(token)
    Digest::SHA256.hexdigest(token.to_s)
  end

  def self.find_by_token(token)
    find_by(token: digest(token))
  end

  def current?
    !renew?
  end

  def renew?
    !verify_id_token.valid?
  end

  def cookie_token_match_for?(cookie_token)
    id_token == cookie_token.to_s
  end

private

  def verify_id_token
    @verify_id_token ||= VerifyToken.new(id_token).call
  end
end
