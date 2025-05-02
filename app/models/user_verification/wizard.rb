module UserVerification
  class Wizard < WizardSteps::Base
    delegate :govuk_notifier_application_template_id,
             :govuk_notifier_registration_template_id,
             :application_support_email,
             to: :TradeTariffDevHub

    APPLICATION_REFERENCE_LENGTH = 8

    self.steps = [
      Steps::Details,
      Steps::ReviewAnswers,
    ]

    def email_address
      @context[:email_address]
    end

    def current_user
      @context[:current_user]
    end

    def do_complete
      if organisation.application_reference.blank?
        organisation.update!(
          eori_number: answers["eori_number"],
          uk_acs_reference: answers["ukacs_reference"],
          organisation_name: answers["organisation_name"],
          application_reference: application_reference,
          status: :pending,
        )

        current_user.email_address = answers["email_address"]
        current_user.save! if current_user.changed?

        send_email_now(current_user)
      end

      organisation.application_reference
    end

    delegate :organisation, to: :current_user

    def answers
      @answers ||= reviewable_answers_by_step[UserVerification::Steps::Details]
    end

    def application_reference
      @application_reference ||= current_user.organisation.application_reference.presence ||
        SecureRandom.hex(APPLICATION_REFERENCE_LENGTH / 2)
    end

    def send_email_now(current_user)
      send_registration_email_now(current_user)
      send_support_email_now(current_user)
    end

    def send_registration_email_now(current_user)
      Rails.logger.info("Sending registration email to #{current_user.email_address}")

      notifier_service.call(
        current_user.email_address,
        govuk_notifier_registration_template_id,
        reference: application_reference,
      )
    end

    def send_support_email_now(current_user)
      Rails.logger.info("Sending support email to #{application_support_email}")

      organisation = current_user.organisation

      notifier_service.call(
        application_support_email,
        govuk_notifier_application_template_id,
        organisation: organisation.organisation_name,
        reference: organisation.application_reference,
        eori: organisation.eori_number,
        ukc: organisation.uk_acs_reference,
        email: current_user.email_address,
        scp_email: current_user.email_address,
      )
    end

    def notifier_service
      @notifier_service ||= GovukNotifier.new
    end
  end
end
