# frozen_string_literal: true

RSpec.describe SessionAuthentication, type: :controller do
  concern_class = described_class

  controller(ApplicationController) do
    include concern_class

    def index
      render plain: "OK"
    end
  end

  before do
    routes.draw { get "index" => "anonymous#index" }
  end

  let(:current_user) { create(:user) }
  let(:plain_token) { SecureRandom.uuid }
  let(:id_token_value) { "test-id-token" }

  before do
    allow(TradeTariffDevHub).to receive(:id_token_cookie_name).and_return(:id_token)
  end

  describe "#authenticated?" do
    context "when the session has exceeded the 4-hour absolute lifetime" do
      it "returns false" do
        create(:session, user: current_user, token: plain_token, id_token: id_token_value,
               expires_at: 1.second.ago, last_active_at: 1.minute.ago)
        session[:token] = plain_token
        cookies[:id_token] = id_token_value

        expect(controller.send(:authenticated?)).to be(false)
      end
    end

    context "when the session has been inactive for more than 15 minutes" do
      it "returns false" do
        create(:session, user: current_user, token: plain_token, id_token: id_token_value,
               expires_at: 2.hours.from_now, last_active_at: 16.minutes.ago)
        session[:token] = plain_token
        cookies[:id_token] = id_token_value

        expect(controller.send(:authenticated?)).to be(false)
      end
    end

    context "when the session is within both time limits" do
      let(:valid_verify_result) { VerifyToken::Result.new(valid: true, payload: {}, reason: nil) }

      it "returns true" do
        create(:session, user: current_user, token: plain_token, id_token: id_token_value,
               expires_at: 2.hours.from_now, last_active_at: 5.minutes.ago)
        session[:token] = plain_token
        cookies[:id_token] = id_token_value
        allow(VerifyToken).to receive(:new).and_return(instance_double(VerifyToken, call: valid_verify_result))

        expect(controller.send(:authenticated?)).to be(true)
      end
    end
  end
end
