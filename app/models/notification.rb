class Notification
  INVITATION_TEMPLATE_ID = "ec674766-30ab-40a1-87e6-c7b43e80ae9b".freeze
  REFERENCE_CHARS = [("A".."Z"), ("0".."9")].map(&:to_a).flatten.freeze
  REFERENCE_LENGTH = 10
  REFERENCE_PREFIX = "PORTAL-".freeze

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
  end
end
