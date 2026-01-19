# == Schema Information
#
# Table name: invitations
#
#  id              :uuid             not null, primary key
#  invitee_email   :string           not null
#  user_id         :uuid             not null
#  organisation_id :uuid             not null
#  status          :enum             default("pending"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_invitations_on_invitee_email    (invitee_email)
#  index_invitations_on_organisation_id  (organisation_id)
#  index_invitations_on_user_id          (user_id)
#

class Invitation < ApplicationRecord
  has_paper_trail

  belongs_to :organisation
  belongs_to :user

  validate :validate_invitee_email

  attribute :status, :string

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

    # Restrict admin domain emails to admin organisations only
    if invitee_email&.end_with?("@#{TradeTariffDevHub.admin_domain}") && !organisation.admin?
      errors.add(:invitee_email, :admin_only, domain: TradeTariffDevHub.admin_domain)
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
