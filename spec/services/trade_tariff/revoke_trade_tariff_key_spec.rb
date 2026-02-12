# frozen_string_literal: true

RSpec.describe TradeTariff::RevokeTradeTariffKey do
  subject(:revoke_trade_tariff_key) do
    described_class.new(api_gateway_client: api_gateway_client)
  end

  let(:api_gateway_client) { instance_double(Aws::APIGateway::Client) }

  describe "#call" do
    context "when key has api_gateway_id (Cognito-provisioned)" do
      let(:trade_tariff_key) { create(:trade_tariff_key, :cognito_provisioned, enabled: true) }

      before do
        allow(api_gateway_client).to receive(:update_api_key).with(
          api_key: trade_tariff_key.api_gateway_id,
          patch_operations: [{ op: "replace", path: "/enabled", value: "false" }],
        )
      end

      it "disables the API Gateway key and marks the record as revoked", :aggregate_failures do
        revoke_trade_tariff_key.call(trade_tariff_key)

        expect(api_gateway_client).to have_received(:update_api_key).with(
          api_key: trade_tariff_key.api_gateway_id,
          patch_operations: [{ op: "replace", path: "/enabled", value: "false" }],
        )
        expect(trade_tariff_key.reload).to be_revoked
        expect(trade_tariff_key.revoked_at).to be_within(2.seconds).of(Time.current)
      end

      it "can be called multiple times safely" do
        revoke_trade_tariff_key.call(trade_tariff_key)
        revoke_trade_tariff_key.call(trade_tariff_key)

        expect(trade_tariff_key.reload).to be_revoked
      end
    end

    context "when key has no api_gateway_id (legacy)" do
      let(:trade_tariff_key) { create(:trade_tariff_key, api_gateway_id: nil, enabled: true) }

      before do
        allow(api_gateway_client).to receive(:update_api_key)
        revoke_trade_tariff_key.call(trade_tariff_key)
      end

      it "does not call API Gateway" do
        expect(api_gateway_client).not_to have_received(:update_api_key)
      end

      it "marks the record as revoked" do
        expect(trade_tariff_key.reload).to be_revoked
      end

      it "sets revoked_at" do
        expect(trade_tariff_key.revoked_at).to be_present
      end
    end

    context "when API Gateway returns NotFoundException" do
      let(:trade_tariff_key) { create(:trade_tariff_key, :cognito_provisioned, enabled: true) }

      before do
        allow(Rails.logger).to receive(:warn)
        allow(api_gateway_client).to receive(:update_api_key)
          .and_raise(Aws::APIGateway::Errors::NotFoundException.new(nil, "Not found"))
      end

      it "raises ExternalRevokeError and does not revoke the database record", :aggregate_failures do
        expect { revoke_trade_tariff_key.call(trade_tariff_key) }.to raise_error(TradeTariff::RevokeTradeTariffKey::ExternalRevokeError)
        expect(trade_tariff_key.reload).to be_active
      end
    end

    context "when API Gateway call fails with StandardError" do
      let(:trade_tariff_key) { create(:trade_tariff_key, :cognito_provisioned, enabled: true) }

      before do
        allow(Rails.logger).to receive(:error)
        allow(api_gateway_client).to receive(:update_api_key)
          .and_raise(StandardError.new("Service unavailable"))
      end

      it "raises ExternalRevokeError and does not revoke the database record", :aggregate_failures do
        expect { revoke_trade_tariff_key.call(trade_tariff_key) }.to raise_error(TradeTariff::RevokeTradeTariffKey::ExternalRevokeError)
        expect(trade_tariff_key.reload).to be_active
      end
    end
  end
end
