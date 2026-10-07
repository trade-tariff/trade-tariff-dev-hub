require "rake"

# rubocop:disable RSpec/DescribeMethod
RSpec.describe Rake::Task, "cleanup:api_keys" do
  # rubocop:enable RSpec/DescribeMethod
  subject(:task) { described_class["cleanup:api_keys"] }

  let(:environment) { "development" }
  let(:cleanup_enabled) { "true" }
  let(:deleter) { instance_double(DeleteApiKey, call: true) }

  around do |example|
    original_environment = ENV["ENVIRONMENT"]
    original_flag = ENV["CLEANUP_PLAYWRIGHT_KEYS_ENABLED"]
    ENV["ENVIRONMENT"] = environment
    ENV["CLEANUP_PLAYWRIGHT_KEYS_ENABLED"] = cleanup_enabled
    example.run
  ensure
    ENV["ENVIRONMENT"] = original_environment
    ENV["CLEANUP_PLAYWRIGHT_KEYS_ENABLED"] = original_flag
  end

  before do
    described_class.define_task(:environment)
    Rake.application.rake_require("tasks/cleanup", [Rails.root.join("lib").to_s])
    task.reenable
    allow(DeleteApiKey).to receive(:new).and_return(deleter)
  end

  it "deletes only matching API keys across organisations when explicitly enabled", :aggregate_failures do
    admin_org = create(:organisation, :admin)
    non_admin_org = create(:organisation)
    admin_key = create(:api_key, organisation: admin_org, description: "playwright-123")
    user_key = create(:api_key, organisation: non_admin_org, description: "playwright-456")
    create(:api_key, organisation: non_admin_org, description: "customer-key")

    expect { task.invoke }.to output(/Deleted 2 playwright API key\(s\)/).to_stdout

    expect(deleter).to have_received(:call).with(admin_key)
    expect(deleter).to have_received(:call).with(user_key)
    expect(deleter).to have_received(:call).twice
  end

  it "reports when there are no matching keys", :aggregate_failures do
    expect { task.invoke }.to output("No playwright API keys to delete\n").to_stdout
    expect(deleter).not_to have_received(:call)
  end

  shared_examples "blocked cleanup" do
    it "exits unsuccessfully before querying or deleting keys", :aggregate_failures do
      allow(ApiKey).to receive(:where).and_call_original

      expect { task.invoke }
        .to output(/Cleanup requires ENVIRONMENT=development and CLEANUP_PLAYWRIGHT_KEYS_ENABLED=true/).to_stderr
        .and raise_error(SystemExit) { |error| expect(error.status).to eq(1) }

      expect(ApiKey).not_to have_received(:where)
      expect(DeleteApiKey).not_to have_received(:new)
    end
  end

  context "without the cleanup flag" do
    let(:cleanup_enabled) { nil }

    include_examples "blocked cleanup"
  end

  context "with a disabled cleanup flag" do
    let(:cleanup_enabled) { "false" }

    include_examples "blocked cleanup"
  end

  context "with a non-literal true cleanup flag" do
    let(:cleanup_enabled) { "TRUE" }

    include_examples "blocked cleanup"
  end

  context "when the environment is production" do
    let(:environment) { "production" }

    include_examples "blocked cleanup"
  end

  context "when the environment is staging" do
    let(:environment) { "staging" }

    include_examples "blocked cleanup"
  end

  context "without an environment" do
    let(:environment) { nil }

    include_examples "blocked cleanup"
  end
end
