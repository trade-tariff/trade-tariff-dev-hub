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

    before do
      allow(Rails.env).to receive(:development?).and_return(true)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("CLEANUP_PLAYWRIGHT_KEYS_ENABLED").and_return(nil)
      allow(Organisation).to receive(:admin_organisation).and_return(admin_org)
    end

    context "when admin organisation has no playwright keys" do
      it "does not call DeleteApiKey", :aggregate_failures do
        expect { described_class["cleanup:api_keys"].invoke }.to output(/\A.*\z/m).to_stdout

        expect(DeleteApiKey).not_to have_received(:new)
      end
    end

    context "when admin organisation has playwright-prefixed keys" do
      let!(:playwright_key) do
        create(:api_key, organisation: admin_org, description: "playwright-#{Time.zone.now.to_i}")
      end

      it "deletes only keys with description starting with playwright-", :aggregate_failures do
        deleter = instance_double(DeleteApiKey, call: true)
        allow(DeleteApiKey).to receive(:new).and_return(deleter)

        expect { described_class["cleanup:api_keys"].invoke }.to output(/\A.*\z/m).to_stdout

        expect(deleter).to have_received(:call).with(playwright_key)
      end
    end

    context "when admin organisation has mixed keys" do
      let!(:playwright_key) do
        create(:api_key, organisation: admin_org, description: "playwright-test")
      end
      let!(:other_key) do
        create(:api_key, organisation: admin_org, description: "My real key")
      end

      it "deletes only the playwright key", :aggregate_failures do
        deleter = instance_double(DeleteApiKey, call: true)
        allow(DeleteApiKey).to receive(:new).and_return(deleter)

        expect { described_class["cleanup:api_keys"].invoke }.to output(/\A.*\z/m).to_stdout

        expect(deleter).to have_received(:call).with(playwright_key)
        expect(deleter).not_to have_received(:call).with(other_key)
      end
    end
  end

  context "when CLEANUP_PLAYWRIGHT_KEYS_ENABLED=true (deployed dev)" do
    let(:admin_org) { create(:organisation, organisation_name: "Admin Dev Org") }

    before do
      allow(Rails.env).to receive(:development?).and_return(false)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("CLEANUP_PLAYWRIGHT_KEYS_ENABLED").and_return("true")
      allow(Organisation).to receive(:admin_organisation).and_return(admin_org)
    end

    it "runs cleanup for admin org", :aggregate_failures do
      create(:api_key, organisation: admin_org, description: "playwright-123")
      deleter = instance_double(DeleteApiKey, call: true)
      allow(DeleteApiKey).to receive(:new).and_return(deleter)

      expect { described_class["cleanup:api_keys"].invoke }.to output(/\A.*\z/m).to_stdout

      expect(DeleteApiKey).to have_received(:new)
      expect(deleter).to have_received(:call)
    end
  end
end
