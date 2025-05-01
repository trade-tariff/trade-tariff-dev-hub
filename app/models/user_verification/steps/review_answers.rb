module UserVerification
  module Steps
    class ReviewAnswers < WizardSteps::Step
      VALID_TERMS = ["", "1", "2", "3", "4"].freeze

      attribute :terms

      validate :validate_terms

      def validate_terms
        return if terms == VALID_TERMS

        errors.add(:terms, :blank)
      end

      def answers
        @answers ||= @wizard.reviewable_answers_by_step[UserVerification::Steps::Details]
      end
    end
  end
end
