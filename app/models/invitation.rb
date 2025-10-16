class Invitation < ApplicationRecord
  has_paper_trail

  belongs_to :organisation
  belongs_to :user

  validate :validate_invitee_email
  validates :invitee_email, uniqueness: { case_sensitive: false }

  enum :status, {
    pending: "pending",
    accepted: "accepted",
    declined: "declined",
    expired: "expired",
    revoked: "revoked",
  }, default: "pending"

  def validate_invitee_email
    if invitee_email.blank?
      errors.add(:invitee_email, :blank)
    else
      errors.add(:invitee_email, :invalid_format) unless invitee_email.match?(URI::MailTo::EMAIL_REGEXP)
    end
  end
end
