class Session < ApplicationRecord
  belongs_to :user

  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true
  validates :raw_info, presence: true

  def raw_info
    Hashie::Mash.new(super || {})
  end

  def update_profile_url
    raw_info.profile.to_s
  end

  def manage_team_url
    raw_info["bas:groupProfile"].to_s
  end

  def email_address
    raw_info.email.to_s
  end

  def organisation_account?
    manage_team_url.present?
  end

  def expired?
    expires_at < Time.zone.now
  end
end
