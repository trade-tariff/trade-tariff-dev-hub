# frozen_string_literal: true

require "rake"

# Rake task specs: second argument is the task name, not a method (e.g. .invoke).
# rubocop:disable RSpec/DescribeMethod
RSpec.describe Rake::Task, "cleanup:api_keys" do
  # rubocop:enable RSpec/DescribeMethod
  before do
    Rails.application.load_tasks if described_class.tasks.none? { |t| t.name == "cleanup:api_keys" }
    described_class["cleanup:api_keys"].reenable
    allow(DeleteApiKey).to receive(:new).and_return(instance_double(DeleteApiKey, call: true))
  end

  context "when not in development and CLEANUP_PLAYWRIGHT_KEYS_ENABLED is not set" do
    before do
      allow(Rails.env).to receive(:development?).and_return(false)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("CLEANUP_PLAYWRIGHT_KEYS_ENABLED").and_return(nil)
    end

    it "skips without deleting", :aggregate_failures do
      count_before = ApiKey.count
      expect { described_class["cleanup:api_keys"].invoke }.to output(/\A.*\z/m).to_stdout
      expect(ApiKey.count).to eq(count_before)
    end
  end

  context "when in development" do
    let(:admin_org) { create(:organisation, organisation_name: "Admin Dev Org") }
    let(:non_admin_org) { create(:organisation, organisation_name: "User Dev Org") }

    before do
      allow(Rails.env).to receive(:development?).and_return(true)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("CLEANUP_PLAYWRIGHT_KEYS_ENABLED").and_return(nil)
    end

    context "when no organisations have playwright keys" do
      it "does not call DeleteApiKey", :aggregate_failures do
        expect { described_class["cleanup:api_keys"].invoke }.to output(/\A.*\z/m).to_stdout

        expect(DeleteApiKey).not_to have_received(:new)
      end
    end

    context "when organisations have playwright-prefixed keys" do
      let!(:admin_playwright_key) do
        create(:api_key, organisation: admin_org, description: "playwright-#{Time.zone.now.to_i}")
      end
      let!(:user_playwright_key) do
        create(:api_key, organisation: non_admin_org, description: "playwright-test-key")
      end

      it "deletes playwright keys from all organisations", :aggregate_failures do
        deleter = instance_double(DeleteApiKey, call: true)
        allow(DeleteApiKey).to receive(:new).and_return(deleter)

        expect { described_class["cleanup:api_keys"].invoke }.to output(/\A.*\z/m).to_stdout

        expect(deleter).to have_received(:call).with(admin_playwright_key)
        expect(deleter).to have_received(:call).with(user_playwright_key)
      end
    end

    context "when organisations have mixed keys" do
      let(:deleter) { instance_double(DeleteApiKey, call: true) }

      before do
        create(:api_key, organisation: admin_org, description: "playwright-test")
        create(:api_key, organisation: admin_org, description: "My real key")
        create(:api_key, organisation: non_admin_org, description: "playwright-user-key")
        create(:api_key, organisation: non_admin_org, description: "User real key")
        allow(DeleteApiKey).to receive(:new).and_return(deleter)
      end

      it "deletes only playwright keys from all organisations", :aggregate_failures do
        expect { described_class["cleanup:api_keys"].invoke }.to output(/\A.*\z/m).to_stdout

        expect(deleter).to have_received(:call).exactly(2).times
      end
    end
  end

  context "when CLEANUP_PLAYWRIGHT_KEYS_ENABLED=true (deployed dev)" do
    let(:admin_org) { create(:organisation, organisation_name: "Admin Dev Org") }
    let(:non_admin_org) { create(:organisation, organisation_name: "User Dev Org") }

    before do
      allow(Rails.env).to receive(:development?).and_return(false)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("CLEANUP_PLAYWRIGHT_KEYS_ENABLED").and_return("true")
      allow(TradeTariffDevHub).to receive(:production_environment?).and_return(false)
    end

    it "runs cleanup for all organisations", :aggregate_failures do
      admin_key = create(:api_key, organisation: admin_org, description: "playwright-123")
      user_key = create(:api_key, organisation: non_admin_org, description: "playwright-456")
      deleter = instance_double(DeleteApiKey, call: true)
      allow(DeleteApiKey).to receive(:new).and_return(deleter)

      expect { described_class["cleanup:api_keys"].invoke }.to output(/\A.*\z/m).to_stdout

      expect(DeleteApiKey).to have_received(:new).twice
      expect(deleter).to have_received(:call).with(admin_key)
      expect(deleter).to have_received(:call).with(user_key)
    end
  end
end
