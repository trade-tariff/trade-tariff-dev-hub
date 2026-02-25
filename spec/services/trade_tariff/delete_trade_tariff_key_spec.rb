# frozen_string_literal: true

RSpec.describe TradeTariff::DeleteTradeTariffKey do
  subject(:delete_trade_tariff_key) do
    described_class.new(identity_client: identity_client, api_gateway_client: api_gateway_client)
  end

  let(:identity_client) { instance_double(Identity::ClientCredentialsApi) }
  let(:api_gateway_client) { instance_double(Aws::APIGateway::Client) }

  describe "#call" do
    context "when key has api_gateway_id (Cognito-provisioned)" do
      let(:trade_tariff_key) { create(:trade_tariff_key, :cognito_provisioned) }

      before do
        allow(api_gateway_client).to receive(:delete_api_key)
        allow(identity_client).to receive(:delete)
      end

      it "destroys the Trade Tariff key after external teardown" do
        trade_tariff_key_id = trade_tariff_key.id
        delete_trade_tariff_key.call(trade_tariff_key)

        expect(TradeTariffKey.find_by(id: trade_tariff_key_id)).to be_nil
      end

      it "calls API Gateway then Identity then destroys the record" do
        call_order = []
        allow(api_gateway_client).to receive(:delete_api_key) { call_order << :api_gateway }
        allow(identity_client).to receive(:delete) { call_order << :identity }
        allow(trade_tariff_key).to receive(:destroy!) { call_order << :destroy }

        delete_trade_tariff_key.call(trade_tariff_key)

        expect(call_order).to eq(%i[api_gateway identity destroy])
      end

      it "calls identity API to delete the Cognito client" do
        delete_trade_tariff_key.call(trade_tariff_key)

        expect(identity_client).to have_received(:delete).with(trade_tariff_key.client_id)
      end

      it "calls API Gateway to delete the API key" do
        delete_trade_tariff_key.call(trade_tariff_key)

        expect(api_gateway_client).to have_received(:delete_api_key).with(api_key: trade_tariff_key.api_gateway_id)
      end
    end

    context "when key has no api_gateway_id (legacy)" do
      let(:trade_tariff_key) { create(:trade_tariff_key, api_gateway_id: nil, usage_plan_id: nil) }

      before do
        allow(identity_client).to receive(:delete)
        allow(api_gateway_client).to receive(:delete_api_key)
      end

      it "destroys the key without calling identity or API Gateway", :aggregate_failures do
        delete_trade_tariff_key.call(trade_tariff_key)

        expect(identity_client).not_to have_received(:delete)
        expect(api_gateway_client).not_to have_received(:delete_api_key)
        expect(TradeTariffKey.find_by(id: trade_tariff_key.id)).to be_nil
      end
    end

    context "when key is already deleted from API Gateway" do
      let(:trade_tariff_key) { create(:trade_tariff_key, :cognito_provisioned) }

      before do
        allow(Rails.logger).to receive(:warn)
        allow(api_gateway_client).to receive(:delete_api_key).and_raise(Aws::APIGateway::Errors::NotFoundException.new(nil, "Not found"))
        allow(identity_client).to receive(:delete)
      end

      it "still destroys the DB record" do
        delete_trade_tariff_key.call(trade_tariff_key)

        expect(TradeTariffKey.find_by(id: trade_tariff_key.id)).to be_nil
      end
    end

    context "when API Gateway delete fails" do
      let(:trade_tariff_key) { create(:trade_tariff_key, :cognito_provisioned) }

      before do
        allow(Rails.logger).to receive(:error)
        allow(api_gateway_client).to receive(:delete_api_key).and_raise(StandardError.new("Service unavailable"))
      end

      it "raises ExternalDeleteError" do
        expect { delete_trade_tariff_key.call(trade_tariff_key) }.to raise_error(TradeTariff::DeleteTradeTariffKey::ExternalDeleteError)
      end

      it "does not destroy the record" do
        delete_trade_tariff_key.call(trade_tariff_key)
      rescue TradeTariff::DeleteTradeTariffKey::ExternalDeleteError
        expect(TradeTariffKey.find_by(id: trade_tariff_key.id)).to be_present
      end
    end

    context "when Identity delete fails" do
      let(:trade_tariff_key) { create(:trade_tariff_key, :cognito_provisioned) }

      before do
        allow(Rails.logger).to receive(:error)
        allow(api_gateway_client).to receive(:delete_api_key)
        allow(identity_client).to receive(:delete).and_raise(StandardError.new("Identity error"))
      end

      it "raises ExternalDeleteError" do
        expect { delete_trade_tariff_key.call(trade_tariff_key) }.to raise_error(TradeTariff::DeleteTradeTariffKey::ExternalDeleteError)
      end

      it "does not destroy the record" do
        delete_trade_tariff_key.call(trade_tariff_key)
      rescue TradeTariff::DeleteTradeTariffKey::ExternalDeleteError
        expect(TradeTariffKey.find_by(id: trade_tariff_key.id)).to be_present
      end
    end
  end
end
