module UserVerification
  class Wizard < WizardSteps::Base
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
      unless organisation.application_reference
        organisation.update!(
          uk_acs_reference: answers["ukacs_reference"],
          organisation_name: answers["organisation_name"],
          application_reference: answers["application_reference"],
          status: :pending,
        )

        current_user.email_address = answers["email_address"]
        current_user.save! if current_user.changed?
      end

      organisation.application_reference
    end

    delegate :organisation, to: :current_user

    def answers
      @answers ||= reviewable_answers_by_step[UserVerification::Steps::Details]
    end

    def application_reference
      current_user.organisation.application_reference.presence || SecureRandom.hex(APPLICATION_REFERENCE_LENGTH / 2)
    end
  end
end
