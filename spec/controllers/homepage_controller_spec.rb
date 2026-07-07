# frozen_string_literal: true

RSpec.describe HomepageController, type: :controller do
  describe "GET #index" do
    let(:current_user) { create(:user) }
    let(:plain_token) { SecureRandom.uuid }
    let(:id_token_value) { "test-id-token" }

    before do
      allow(TradeTariffDevHub).to receive(:id_token_cookie_name).and_return(:id_token)
    end

    context "when user has no session" do
      it "returns http success" do
        get :index
        expect(response).to have_http_status(:success)
      end
    end

    context "when user has a valid identity session" do
      let(:valid_verify_result) { VerifyToken::Result.new(valid: true, payload: {}, reason: nil) }

      before do
        session[:token] = plain_token
        cookies[TradeTariffDevHub.id_token_cookie_name] = id_token_value
        create(:session, user: current_user, token: plain_token, id_token: id_token_value)
        allow(VerifyToken).to receive(:new).with(id_token_value).and_return(
          instance_double(VerifyToken, call: valid_verify_result),
        )
      end

      it "redirects to the organisation page" do
        get :index
        expect(response).to redirect_to(organisation_path(current_user.organisation))
      end
    end

    context "when user has a stale identity session" do
      let(:invalid_verify_result) { VerifyToken::Result.new(valid: false, payload: nil, reason: "expired") }

      before do
        session[:token] = plain_token
        cookies[TradeTariffDevHub.id_token_cookie_name] = id_token_value
        create(:session, user: current_user, token: plain_token, id_token: id_token_value)
        allow(VerifyToken).to receive(:new).with(id_token_value).and_return(
          instance_double(VerifyToken, call: invalid_verify_result),
        )
      end

      it "returns http success and clears the session", :aggregate_failures do
        get :index
        expect(response).to have_http_status(:success)
        expect(Session.find_by_token(plain_token)).to be_nil
        expect(session[:token]).to be_nil
      end
    end
  end
end
