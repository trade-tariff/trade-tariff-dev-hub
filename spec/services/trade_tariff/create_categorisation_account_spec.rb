# frozen_string_literal: true

RSpec.describe TradeTariff::CreateCategorisationAccount do
  subject(:provision_account) { described_class.new(key_creator: key_creator) }

  let(:key_creator) { instance_double(TradeTariff::CreateCategorisationKey) }
  let(:trade_tariff_key) { build(:trade_tariff_key, client_id: "client-123") }
  let(:key_result) do
    TradeTariff::CreateTradeTariffKey::CreateResult.new(
      trade_tariff_key: trade_tariff_key,
      client_secret: "secret-once-only",
    )
  end

  before do
    allow(key_creator).to receive(:call).and_return(key_result)
  end

  context "with a valid new email address" do
    subject(:result) { provision_account.call("  Consumer@Example.com ", "  Example Traders Ltd  ") }

    it "creates a user and organisation" do
      expect { result }.to change(User, :count).by(1)
        .and change(Organisation, :count).by(1)
    end

    it "normalises the email and gives the user a provisional ID", :aggregate_failures do
      expect(result.user.email_address).to eq("consumer@example.com")
      expect(result.user.user_id).to start_with("preprovisioned-")
    end

    it "creates an organisation that can access Trade Tariff keys", :aggregate_failures do
      expect(result.user.organisation).to have_attributes(
        organisation_name: "Example Traders Ltd",
        description: "Categorisation API organisation for consumer@example.com",
      )
      expect(result.user.organisation.has_role?(Role::TRADE_TARIFF_ROLE_NAME)).to be(true)
    end

    it "creates and returns the categorisation credentials", :aggregate_failures do
      expect(result.categorisation_key).to eq(trade_tariff_key)
      expect(result.client_secret).to eq("secret-once-only")
      expect(key_creator).to have_received(:call).with(result.user.organisation)
    end
  end

  it "rejects an invalid email address before creating anything", :aggregate_failures do
    original_user_count = User.count
    original_organisation_count = Organisation.count

    expect { provision_account.call("not-an-email", "Example Traders Ltd") }
      .to raise_error(ArgumentError, "A valid email address is required")

    expect(User.count).to eq(original_user_count)
    expect(Organisation.count).to eq(original_organisation_count)
    expect(key_creator).not_to have_received(:call)
  end

  it "rejects a blank organisation name before creating anything", :aggregate_failures do
    original_user_count = User.count
    original_organisation_count = Organisation.count

    expect { provision_account.call("consumer@example.com", "  ") }
      .to raise_error(ArgumentError, "Organisation name is required")

    expect(User.count).to eq(original_user_count)
    expect(Organisation.count).to eq(original_organisation_count)
    expect(key_creator).not_to have_received(:call)
  end

  context "when the email address already has an account, ignoring case" do
    subject(:result) { provision_account.call("CONSUMER@example.com", "Example Traders Ltd") }

    let(:organisation) { create(:organisation) }
    let!(:existing_user) { create(:user, email_address: "consumer@example.com", organisation: organisation) }

    it "does not create a new user" do
      expect { result }.not_to change(User, :count)
    end

    it "does not create a new organisation" do
      expect { provision_account.call("CONSUMER@example.com", "Example Traders Ltd") }
        .not_to change(Organisation, :count)
    end

    it "creates a key for the existing user's organisation instead", :aggregate_failures do
      expect(result.user).to eq(existing_user)
      expect(result.categorisation_key).to eq(trade_tariff_key)
      expect(result.client_secret).to eq("secret-once-only")
      expect(key_creator).to have_received(:call).with(organisation)
    end

    it "ignores the organisation_name argument" do
      expect { provision_account.call("CONSUMER@example.com", "") }.not_to raise_error
    end
  end

  it "rolls back the local account when key provisioning fails", :aggregate_failures do
    allow(key_creator).to receive(:call).and_raise(StandardError, "AWS failed")
    original_user_count = User.count
    original_organisation_count = Organisation.count

    expect { provision_account.call("consumer@example.com", "Example Traders Ltd") }
      .to raise_error(StandardError, "AWS failed")

    expect(User.count).to eq(original_user_count)
    expect(Organisation.count).to eq(original_organisation_count)
  end
end
