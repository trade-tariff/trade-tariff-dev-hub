# frozen_string_literal: true

RSpec.describe TradeTariff::CreateCategorisationKey do
  subject(:create_key) { described_class.new(key_creator: key_creator) }

  let(:organisation) { create(:organisation) }
  let(:key_creator) { instance_double(TradeTariff::CreateTradeTariffKey) }
  let(:result) { instance_double(TradeTariff::CreateTradeTariffKey::CreateResult) }

  before do
    allow(key_creator).to receive(:call).and_return(result)
  end

  it "creates a categorisation-only key", :aggregate_failures do
    expect(create_key.call(organisation)).to eq(result)

    expect(key_creator).to have_received(:call).with(
      organisation.id,
      "Categorisation API key",
      %w[categorisation],
    )
  end

  it "refuses to provision a second active categorisation key", :aggregate_failures do
    create(:trade_tariff_key, organisation: organisation, scopes: %w[categorisation])

    expect { create_key.call(organisation) }
      .to raise_error(ArgumentError, "Organisation already has an active categorisation key")
    expect(key_creator).not_to have_received(:call)
  end

  it "allows replacement after the existing categorisation key is revoked" do
    create(:trade_tariff_key, organisation: organisation, scopes: %w[categorisation], enabled: false)

    expect { create_key.call(organisation) }.not_to raise_error
  end

  it "requires a persisted organisation", :aggregate_failures do
    expect { create_key.call(Organisation.new) }
      .to raise_error(ArgumentError, "Organisation must be persisted")
    expect(key_creator).not_to have_received(:call)
  end
end
