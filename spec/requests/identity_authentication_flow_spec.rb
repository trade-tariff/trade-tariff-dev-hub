# frozen_string_literal: true

RSpec.describe "Identity authentication flow", type: :request do
  let(:current_user) { create(:user) }
  let(:id_token_value) { "encrypted-id-token-from-identity-service" }
  let(:identity_consumer_url) { "https://id.dev.trade-tariff.service.gov.uk/portal" }

  let(:decoded_id_token) do
    {
      "sub" => current_user.user_id,
      "email" => current_user.email_address,
    }
  end

  let(:valid_verify_result) do
    VerifyToken::Result.new(valid: true, payload: decoded_id_token, reason: nil)
  end

  before do
    allow(TradeTariffDevHub).to receive_messages(identity_consumer_url: identity_consumer_url, id_token_cookie_name: :id_token)
    # Stub VerifyToken to simulate identity service token verification
    allow(VerifyToken).to receive(:new).with(id_token_value).and_return(
      instance_double(VerifyToken, call: valid_verify_result),
    )
  end

  describe "full authentication flow from identity service callback" do
    context "when in development environment with dev bypass enabled" do
      before do
        allow(TradeTariffDevHub).to receive_messages(production_environment?: false, dev_bypass_auth_enabled?: true)
        Rails.application.reload_routes!
      end

      context "when user authenticates via identity service" do
        it "allows user to access protected routes without redirecting to dev login", :aggregate_failures do
          cookies[TradeTariffDevHub.id_token_cookie_name] = id_token_value

          expect { get auth_redirect_path }.to change(Session, :count).by(1)
          expect(response).to redirect_to(organisation_path(current_user.organisation))

          follow_redirect!
          expect(response).to have_http_status(:ok)

          get api_keys_path
          expect(response).not_to redirect_to(dev_login_path)
          expect(response.status).to be_between(200, 399)
        end

        it "maintains authentication across multiple protected route accesses", :aggregate_failures do
          cookies[TradeTariffDevHub.id_token_cookie_name] = id_token_value
          get auth_redirect_path
          follow_redirect!

          get api_keys_path
          expect(response).not_to redirect_to(dev_login_path)
          expect(response.status).to be_between(200, 399)

          get organisations_path
          expect(response).not_to redirect_to(dev_login_path)
          expect(response.status).to be_between(200, 399)
        end
      end

      context "when user has no identity session" do
        it "redirects to dev login page as fallback" do
          get api_keys_path
          expect(response).to redirect_to(dev_login_path)
        end
      end
    end

    context "when in production environment" do
      before do
        allow(TradeTariffDevHub).to receive(:production_environment?).and_return(true)
      end

      context "when user authenticates via identity service" do
        before do
          current_user.organisation.assign_role!("fpo:full")
        end

        it "allows user to access protected routes", :aggregate_failures do
          cookies[TradeTariffDevHub.id_token_cookie_name] = id_token_value

          get auth_redirect_path
          expect(response).to redirect_to(organisation_path(current_user.organisation))

          follow_redirect!
          get api_keys_path
          expect(response).to have_http_status(:ok)
          expect(response).not_to redirect_to(dev_login_path)
        end
      end

      context "when user has no identity session and dev bypass is enabled" do
        before do
          allow(TradeTariffDevHub).to receive(:dev_bypass_auth_enabled?).and_return(true)
        end

        it "redirects to identity service, NOT dev login", :aggregate_failures do
          get api_keys_path
          expect(response).to redirect_to(identity_consumer_url)
          expect(response).not_to redirect_to(dev_login_path)
        end
      end

      context "when user has no identity session and dev bypass is disabled" do
        before do
          allow(TradeTariffDevHub).to receive(:dev_bypass_auth_enabled?).and_return(false)
        end

        it "redirects to identity service" do
          get api_keys_path
          expect(response).to redirect_to(identity_consumer_url)
        end
      end
    end
  end

  describe "when user authenticates then session expires" do
    context "when in development environment with dev bypass enabled" do
      before do
        allow(TradeTariffDevHub).to receive_messages(production_environment?: false, dev_bypass_auth_enabled?: true)
        Rails.application.reload_routes!
      end

      it "redirects to dev login when identity session expires" do
        cookies[TradeTariffDevHub.id_token_cookie_name] = id_token_value
        get auth_redirect_path
        follow_redirect!

        # Clear session and id_token so the next request is unauthenticated
        cookies.delete(Rails.application.config.session_options[:key])
        cookies.delete(TradeTariffDevHub.id_token_cookie_name)

        get api_keys_path
        expect(response).to redirect_to("/dev/login")
      end
    end
  end
end
