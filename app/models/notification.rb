# frozen_string_literal: true

class Notification
  INVITATION_TEMPLATE_ID = NOTIFY_CONFIGURATION.dig(:templates, :developer_portal, :invitation)
  ROLE_REQUEST_TEMPLATE_ID = NOTIFY_CONFIGURATION.dig(:templates, :developer_portal, :role_request_created)
  ROLE_REQUEST_APPROVED_TEMPLATE_ID = NOTIFY_CONFIGURATION.dig(:templates, :developer_portal, :role_request_approved)
  REFERENCE_CHARS = [("A".."Z"), ("0".."9")].map(&:to_a).flatten
  REFERENCE_LENGTH = 10
  REFERENCE_PREFIX = "PORTAL-"

  include ActiveModel::Model

  attr_accessor :email,
                :template_id,
                :email_reply_to_id,
                :personalisation,
                :id

  def reference
    @reference ||= begin
      reference = REFERENCE_PREFIX.dup
      REFERENCE_LENGTH.times do
        reference += REFERENCE_CHARS[Kernel.rand(REFERENCE_CHARS.length)]
      end
      reference
    end
  end

  class << self
    def build_for_invitation(invitation)
      new(
        email: invitation.invitee_email,
        template_id: INVITATION_TEMPLATE_ID,
        personalisation: {
          inviter_email_address: invitation.user.email_address,
          invitation_url: TradeTariffDevHub.govuk_app_domain,
          support_email: TradeTariffDevHub.application_support_email,
        },
      )
    end

    def build_for_role_request(role_request)
      role_description = role_description_for(role_request.role_name)

      # NOTE: We need to fan out to every configured admin email on the system
      User.admin_emails.map do |admin_email|
        new(
          email: admin_email,
          template_id: ROLE_REQUEST_TEMPLATE_ID,
          personalisation: {
            organisation_name: role_request.organisation.organisation_name,
            requester_email: role_request.user.email_address,
            role_name: role_request.role_name,
            role_description: role_description,
            note: role_request.note.presence || "No note provided",
            admin_url: "#{TradeTariffDevHub.govuk_app_domain}/admin/role_requests",
          },
        )
      end
    end

    def build_for_role_request_approved(role_request)
      role_description = role_description_for(role_request.role_name)
      new(
        email: role_request.user.email_address,
        template_id: ROLE_REQUEST_APPROVED_TEMPLATE_ID,
        personalisation: {
          organisation_name: role_request.organisation.organisation_name,
          role_name: role_request.role_name,
          role_description: role_description,
          organisation_url: "#{TradeTariffDevHub.govuk_app_domain}/organisations/#{role_request.organisation.id}",
        },
      )
    end

  private

    def role_description_for(role_name)
      role = Role.find_by(name: role_name)
      role&.description || role_name
    end
  end
end
