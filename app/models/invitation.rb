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

    if new_record? && active_invitation.present?
      errors.add(:invitee_email, :taken)
    end

    if active_membership.present? && active_membership.organisation_id == organisation_id
      errors.add(:invitee_email, :already_member)
    end

    if active_membership.present? && active_membership.organisation_id != organisation_id
      errors.add(:invitee_email, :member_elsewhere)
    end
  end

  def active_invitation
    @active_invitation ||= Invitation.order(updated_at: :desc)
      .where.not(status: "revoked")
      .where("LOWER(invitee_email) = ?", invitee_email.downcase)
      .first
  end

  def active_membership
    @active_membership ||= User.where("LOWER(email_address) = ?", invitee_email.downcase).first
  end

  def send_email
    notification = Notification.build_for_invitation(self)

    return true if Rails.env.development?

    SendNotification.new(notification).call
  end
end
