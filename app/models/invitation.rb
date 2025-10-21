class Invitation < ApplicationRecord
  has_paper_trail

  belongs_to :organisation
  belongs_to :user

  validate :validate_invitee_email

  enum :status, {
    accepted: "accepted",
    pending: "pending",
    revoked: "revoked",
  }, default: "pending"

  def validate_invitee_email
    if invitee_email.blank?
      errors.add(:invitee_email, :blank)
    else
      errors.add(:invitee_email, :invalid_format) unless invitee_email.match?(URI::MailTo::EMAIL_REGEXP)
    end

    return unless new_record?

    errors.add(:invitee_email, :taken) if active_invitation.present?
  end

  def active_invitation
    @active_invitation ||= Invitation.order(updated_at: :desc)
      .where.not(status: "revoked")
      .where("LOWER(invitee_email) = ?", invitee_email.downcase)
      .first
  end
end
