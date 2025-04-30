module UserVerification
  class StepsController < AuthenticatedController
    include WizardSteps

    def on_complete(result)
      redirect_to action: :completed, application_reference: result
    end

  private

    self.wizard_class = Wizard

    def wizard_context
      {
        email_address: user_profile["email"],
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
  end
end
