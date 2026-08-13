require "rake"

# rubocop:disable RSpec/DescribeMethod
RSpec.describe Rake::Task, "categorisation_keys:provision" do
  # rubocop:enable RSpec/DescribeMethod
  subject(:task) { described_class["categorisation_keys:provision"] }

  let(:organisation) { create(:organisation, organisation_name: "Approved Consumer") }
  let(:service) { instance_double(TradeTariff::CreateCategorisationKey) }
  let(:trade_tariff_key) { build(:trade_tariff_key, client_id: "client-123") }
  let(:result) do
    TradeTariff::CreateTradeTariffKey::CreateResult.new(
      trade_tariff_key: trade_tariff_key,
      client_secret: "secret-once-only",
    )
  end

  before do
    described_class.define_task(:environment)
    Rake.application.rake_require("tasks/categorisation_keys", [Rails.root.join("lib").to_s])
    task.reenable
    allow(TradeTariff::CreateCategorisationKey).to receive(:new).and_return(service)
    allow(service).to receive(:call).and_return(result)
  end

  it "provisions one key after the operator confirms the organisation name", :aggregate_failures do
    allow($stdin).to receive(:gets).and_return("yes\n")

    expect { task.invoke(organisation.id) }
      .to output(/Approved Consumer.*\[y\/N\].*Categorisation API key created.*client-123.*secret-once-only/m).to_stdout

    expect(service).to have_received(:call).with(organisation)
  end

  it "accepts y as confirmation" do
    allow($stdin).to receive(:gets).and_return("y\n")

    expect { task.invoke(organisation.id) }.to output(/Categorisation API key created/).to_stdout
  end

  it "defaults to no when the operator presses Enter", :aggregate_failures do
    allow($stdin).to receive(:gets).and_return("\n")

    expect { task.invoke(organisation.id) }
      .to output(/Provision a Categorisation API key/).to_stdout
      .and output(/Provisioning cancelled/).to_stderr
      .and raise_error(SystemExit, /Provisioning cancelled/)
    expect(service).not_to have_received(:call)
  end

  it "defaults to no when input is unavailable", :aggregate_failures do
    allow($stdin).to receive(:gets).and_return(nil)

    expect { task.invoke(organisation.id) }
      .to output(/Provision a Categorisation API key/).to_stdout
      .and output(/Provisioning cancelled/).to_stderr
      .and raise_error(SystemExit, /Provisioning cancelled/)
    expect(service).not_to have_received(:call)
  end

  it "cancels when the operator enters no", :aggregate_failures do
    allow($stdin).to receive(:gets).and_return("no\n")

    expect { task.invoke(organisation.id) }
      .to output(/Provision a Categorisation API key/).to_stdout
      .and output(/Provisioning cancelled/).to_stderr
      .and raise_error(SystemExit, /Provisioning cancelled/)
    expect(service).not_to have_received(:call)
  end

  it "requires an organisation ID", :aggregate_failures do
    expect { task.invoke }
      .to output(/Organisation ID is required/).to_stderr
      .and raise_error(SystemExit, /Organisation ID is required/)
    expect(service).not_to have_received(:call)
  end

  it "refuses an unknown organisation ID", :aggregate_failures do
    expect { task.invoke(SecureRandom.uuid) }
      .to output(/was not found/).to_stderr
      .and raise_error(SystemExit, /was not found/)
    expect(service).not_to have_received(:call)
  end
end
