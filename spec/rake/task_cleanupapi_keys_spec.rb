require "rake"

# rubocop:disable RSpec/DescribeMethod
RSpec.describe Rake::Task, "cleanup:api_keys" do
  # rubocop:enable RSpec/DescribeMethod
  before do
    Rails.application.load_tasks
    described_class["cleanup:api_keys"].reenable
    allow(DeleteApiKey).to receive(:new).and_return(instance_double(DeleteApiKey, call: true))
  end

  let(:admin_org) { create(:organisation, organisation_name: "Admin Dev Org") }
  let(:non_admin_org) { create(:organisation, organisation_name: "User Dev Org") }

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
