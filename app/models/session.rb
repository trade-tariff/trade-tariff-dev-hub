# == Schema Information
#
# Table name: sessions
#
#  id         :uuid             not null, primary key
#  token      :string           not null
#  user_id    :uuid             not null
#  raw_info   :jsonb
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  expires_at :datetime
#  id_token   :text             not null
#
# Indexes
#
#  index_sessions_on_token    (token) UNIQUE
#  index_sessions_on_user_id  (user_id)
#

class Session < ApplicationRecord
  belongs_to :user

  validates :token, presence: true, uniqueness: true
  validates :id_token, presence: true

  def renew?
    decoded_id_token.nil?
  end

private

  def decoded_id_token
    @decoded_id_token ||= VerifyToken.new(id_token).call
  end
end
