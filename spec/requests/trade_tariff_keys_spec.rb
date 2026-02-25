# frozen_string_literal: true

RSpec.describe "Trade Tariff keys", type: :request do
  include_context "with authenticated user"

  before do
    current_user.organisation.assign_role!("trade_tariff:full")
  end

  describe "POST /trade_tariff_keys" do
    let(:create_service) { instance_double(TradeTariff::CreateTradeTariffKey) }
    let(:trade_tariff_key) { create(:trade_tariff_key, :cognito_provisioned, organisation: current_user.organisation) }
    let(:create_result) do
      TradeTariff::CreateTradeTariffKey::CreateResult.new(
        trade_tariff_key: trade_tariff_key,
        client_secret: "secret-once-only",
      )
    end

    before do
      allow(TradeTariff::CreateTradeTariffKey).to receive(:new).and_return(create_service)
    end

    context "when create succeeds" do
      before do
        allow(create_service).to receive(:call).and_return(create_result)
      end

      it "renders the create template with key and secret", :aggregate_failures do
        post trade_tariff_keys_path, params: { trade_tariff_key_description: "My key" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Trade Tariff API key created")
        expect(response.body).to include(trade_tariff_key.client_id)
        expect(response.body).to include("secret-once-only")
      end
    end

    context "when create raises ArgumentError" do
      before do
        allow(create_service).to receive(:call).and_raise(ArgumentError.new("Config missing"))
      end

      it "re-renders new with alert and does not create a key", :aggregate_failures do
        expect {
          post trade_tariff_keys_path, params: { trade_tariff_key_description: "My key" }
        }.not_to change(TradeTariffKey, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Enter a description for this Trade Tariff API key")
        expect(response.body).to include("Config missing")
      end
    end

    context "when create raises StandardError" do
      before do
        allow(create_service).to receive(:call).and_raise(StandardError.new("Something broke"))
      end

      it "re-renders new with generic alert and does not create a key", :aggregate_failures do
        expect {
          post trade_tariff_keys_path, params: { trade_tariff_key_description: "My key" }
        }.not_to change(TradeTariffKey, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Something went wrong")
        expect(response.body).not_to include("Something broke")
      end
    end
  end

  describe "DELETE /trade_tariff_keys/:id/delete" do
    let(:delete_service) { instance_double(TradeTariff::DeleteTradeTariffKey) }

    before do
      allow(TradeTariff::DeleteTradeTariffKey).to receive(:new).and_return(delete_service)
      allow(delete_service).to receive(:call)
    end

    context "when key is revoked" do
      let!(:trade_tariff_key) do
        create(:trade_tariff_key, :cognito_provisioned, organisation: current_user.organisation, enabled: false)
      end

      it "calls the delete service and redirects with notice", :aggregate_failures do
        delete delete_trade_tariff_key_path(trade_tariff_key)

        expect(response).to redirect_to(trade_tariff_keys_path)
        follow_redirect!
        expect(response.body).to include("Trade Tariff key deleted")
        expect(delete_service).to have_received(:call).with(trade_tariff_key)
      end
    end

    context "when key is active (not revoked)" do
      let!(:trade_tariff_key) do
        create(:trade_tariff_key, :cognito_provisioned, organisation: current_user.organisation, enabled: true)
      end

      it "does not delete the key and redirects with alert", :aggregate_failures do
        expect {
          delete delete_trade_tariff_key_path(trade_tariff_key)
        }.not_to change(TradeTariffKey, :count)

        expect(response).to redirect_to(trade_tariff_keys_path)
        follow_redirect!
        expect(response.body).to include("Only revoked keys can be deleted")
        expect(delete_service).not_to have_received(:call)
      end
    end
  end
end
