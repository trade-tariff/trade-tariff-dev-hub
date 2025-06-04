module UserVerification
  class StepsController < AuthenticatedController
    skip_before_action :require_registration

    include WizardSteps

    def show
      redirect_to api_keys_path if organisation.authorised?
      redirect_to action: :completed if organisation.pending?
      redirect_to action: :rejected if organisation.rejected?
      redirect_to step_path("details") if answers_incomplete?
    end

    def rejected; end

  private

    self.wizard_class = Wizard

    def wizard_context
      {
        email_address: user_session.email_address,
        current_user: current_user,
      }
    end

    def wizard_store_key
      :user_verification
    end

    def step_path(step_id = params[:id])
      user_verification_step_path(step_id)
    end

    def step_param_key
      "#{wizard_store_key}_steps_#{current_step.key}"
    end

    # NOTE: This override supports array type form parameters which needs adding to the gem
    def step_params
      return params.require(step_param_key).permit(terms: []) if review_answers?

      super
    end

    def review_answers?
      params.key?("user_verification_steps_review_answers")
    end

    def answers_incomplete?
      current_step == "review_answers" && !find("details").valid?
    end
  end
end
