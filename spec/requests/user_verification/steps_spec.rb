RSpec.describe "Steps", type: :request do
  include_context "with authenticated user"

  let(:organisation) { create(:organisation, status: :unregistered) }

  before { allow(CheckEoriNumber).to receive(:new).and_return(instance_double(CheckEoriNumber, call: true)) }

  describe "GET /user_verification/steps" do
    it "redirects the user to the first step" do
      get user_verification_steps_path
      expect(response).to redirect_to(user_verification_step_path("details"))
    end
  end

  shared_examples_for "a step that handles different registration statuses" do |step|
    before do
      get user_verification_step_path(step)
    end

    context "when the organisation is authorised" do
      let(:organisation) { create(:organisation, status: :authorised) }

      it "redirects to the completed action" do
        expect(response).to redirect_to(api_keys_path)
      end
    end

    context "when the organisation is pending" do
      let(:organisation) { create(:organisation, status: :pending) }

      it "redirects to the completed action" do
        expect(response).to redirect_to(completed_user_verification_steps_path)
      end
    end

    context "when the organisation is rejected" do
      let(:organisation) { create(:organisation, status: :rejected) }

      it "redirects to the rejected action" do
        expect(response).to redirect_to(rejected_user_verification_steps_path)
      end
    end
  end

  describe "GET /user_verification/steps/details" do
    it_behaves_like "a step that handles different registration statuses", "details"

    it "renders the details step", :aggregate_failures do
      get user_verification_step_path("details")
      expect(response.body).to include("Register for the FPO Commodity Code Identification Tool")
      expect(response).to render_template("user_verification/steps/_details")
    end
  end

  describe "PATCH /user_verification/steps/details" do
    let(:params) do
      {
        user_verification_steps_details: {
          organisation_name: "Flibble Exteriors",
          eori_number: "GB12345678",
          ukacs_reference: "XIUK134123213123",
          email_address: "foo@bar.com",
        },
      }
    end

    context "when the params are valid" do
      it "redirects to the review_answers step" do
        patch user_verification_step_path("details"), params: params

        expect(response).to redirect_to(user_verification_step_path("review_answers"))
      end

      it "sets the answers in the session cookie" do
        patch user_verification_step_path("details"), params: params

        expect(session[:user_verification]).to include("organisation_name", "eori_number", "ukacs_reference", "email_address")
      end
    end

    context "when the params are invalid" do
      let(:params) do
        {
          user_verification_steps_details: {
            organisation_name: nil,
            eori_number: nil,
            ukacs_reference: nil,
            email_address: nil,
          },
        }
      end

      it "renders the details step" do
        patch user_verification_step_path("details"), params: params

        expect(response).to render_template("user_verification/steps/_details")
      end

      it "does not set the answers in the session cookie" do
        patch user_verification_step_path("details"), params: params

        expect(session[:user_verification]).not_to include("organisation_name", "eori_number", "ukacs_reference", "email_address")
      end
    end
  end

  describe "GET /user_verification/steps/review_answers" do
    it_behaves_like "a step that handles different registration statuses", "review_answers"

    it "renders the review_answers step", :aggregate_failures do
      get user_verification_step_path("review_answers")
      expect(response.body).to include("Application details")
      expect(response).to render_template("user_verification/steps/_review_answers")
    end
  end

  describe "PATCH /user_verification/steps/review_answers" do
    context "when the params are valid" do
      let(:extra_session) do
        {
          "user_verification" => {
            "organisation_name" => "Flibble Exteriors",
            "eori_number" => "GB12345678",
            "ukacs_reference" => "XIUK134123213123",
            "email_address" => "foo@bar.com",
          },
        }
      end

      let(:params) do
        { user_verification_steps_review_answers: { terms: ["", "1", "2", "3", "4"] } }
      end

      it "redirects to the completed step" do
        patch user_verification_step_path("review_answers"), params: params

        expect(response).to redirect_to(completed_user_verification_steps_path)
      end
    end

    context "when the params are invalid" do
      let(:params) do
        {
          user_verification_steps_review_answers: {
            terms: ["", "1", "3", "4"],
          },
        }
      end

      let(:extra_session) do
        {
          "user_verification" => {
            "organisation_name" => "Flibble Exteriors",
            "eori_number" => "GB12345678",
            "ukacs_reference" => "XIUK134123213123",
            "email_address" => "foo@bar.com",
          },
        }
      end

      it "renders the review_answers step" do
        patch user_verification_step_path("review_answers"), params: params

        expect(response).to render_template("user_verification/steps/_review_answers")
      end
    end

    context "when the details step answers are invalid" do
      let(:params) do
        {
          user_verification_steps_review_answers: {
            terms: ["", "1", "2", "3", "4"],
          },
        }
      end

      let(:extra_session) do
        {
          "user_verification" => {
            "organisation_name" => "Flibble Exteriors",
            "eori_number" => "GB12345678",
            "email_address" => "foo@bar.com",
          },
        }
      end

      it "redirects to the details step" do
        patch user_verification_step_path("review_answers"), params: params

        expect(response).to redirect_to(user_verification_step_path("details"))
      end
    end
  end
end
