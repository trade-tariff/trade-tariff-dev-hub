# frozen_string_literal: true

RSpec.describe AuthenticatedController, type: :controller do
  # Create a test controller that inherits from AuthenticatedController
  controller(OrganisationsController) do
    def test_action
      render plain: "OK"
    end
  end

  before do
    routes.draw do
      get "test_action" => "organisations#test_action"
      get "/dev/login", to: "dev_auth#new", as: :dev_login
      get "/organisations/:id", to: "organisations#show", as: :organisation
    end
  end

  describe "#require_authentication" do
    let(:current_user) { create(:user) }
    let(:plain_token) { SecureRandom.uuid }
    let(:id_token_value) { "test-id-token" }
    let(:identity_consumer_url) { "https://identity.example.com/portal" }

    before do
      allow(TradeTariffDevHub).to receive_messages(identity_consumer_url: identity_consumer_url, id_token_cookie_name: :id_token)
    end

    context "when in development environment with dev bypass enabled" do
      before do
        allow(TradeTariffDevHub).to receive_messages(production_environment?: false, dev_bypass_auth_enabled?: true)
      end

      context "when user has valid identity session" do
        let(:valid_verify_result) { VerifyToken::Result.new(valid: true, payload: {}, reason: nil) }

        before do
          session[:token] = plain_token
          cookies[TradeTariffDevHub.id_token_cookie_name] = id_token_value
          allow(VerifyToken).to receive(:new).with(id_token_value).and_return(
            instance_double(VerifyToken, call: valid_verify_result),
          )
        end

        it "allows access without redirecting to dev login", :aggregate_failures do
          create(:session, user: current_user, token: plain_token, id_token: id_token_value)
          get :test_action
          expect(response).to have_http_status(:ok)
          expect(response.body).to eq("OK")
          expect(response).not_to redirect_to("/dev/login")
        end
      end

      context "when user has no identity session" do
        before do
          session[:token] = nil
          cookies.delete(TradeTariffDevHub.id_token_cookie_name)
        end

        it "redirects to dev login page" do
          get :test_action
          expect(response).to redirect_to("/dev/login")
        end
      end
    end

    context "when in production environment" do
      before do
        allow(TradeTariffDevHub).to receive(:production_environment?).and_return(true)
      end

      context "when dev bypass is enabled without identity session" do
        before do
          allow(TradeTariffDevHub).to receive(:dev_bypass_auth_enabled?).and_return(true)
          session[:token] = nil
          cookies.delete(TradeTariffDevHub.id_token_cookie_name)
        end

        it "redirects to identity service, not dev login", :aggregate_failures do
          get :test_action
          expect(response).to redirect_to(identity_consumer_url)
          expect(response).not_to redirect_to("/dev/login")
        end
      end

      context "when dev bypass is disabled without identity session" do
        before do
          allow(TradeTariffDevHub).to receive(:dev_bypass_auth_enabled?).and_return(false)
          session[:token] = nil
          cookies.delete(TradeTariffDevHub.id_token_cookie_name)
        end

        it "redirects to identity service" do
          get :test_action
          expect(response).to redirect_to(identity_consumer_url)
        end
      end

      context "when user has valid identity session" do
        let(:valid_verify_result) { VerifyToken::Result.new(valid: true, payload: {}, reason: nil) }

        before do
          current_user.organisation.assign_role!("trade_tariff:full")
          create(:session, user: current_user, token: plain_token, id_token: id_token_value)
          session[:token] = plain_token
          cookies[TradeTariffDevHub.id_token_cookie_name] = id_token_value
          allow(VerifyToken).to receive(:new).with(id_token_value).and_return(
            instance_double(VerifyToken, call: valid_verify_result),
          )
        end

        it "allows access" do
          get :test_action
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
