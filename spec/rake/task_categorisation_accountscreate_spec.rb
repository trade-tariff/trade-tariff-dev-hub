require "rake"

# rubocop:disable RSpec/DescribeMethod
RSpec.describe Rake::Task, "categorisation_accounts:create" do
  # rubocop:enable RSpec/DescribeMethod
  subject(:task) { described_class["categorisation_accounts:create"] }

  let(:email_address) { "consumer@example.com" }
  let(:user) { build(:user, email_address: email_address) }
  let(:service) { instance_double(TradeTariff::CreateCategorisationAccount) }
  let(:trade_tariff_key) { build(:trade_tariff_key, client_id: "client-123") }
  let(:result) do
    TradeTariff::CreateCategorisationAccount::Result.new(
      user: user,
      categorisation_key: trade_tariff_key,
      client_secret: "secret-once-only",
    )
  end

  before do
    described_class.define_task(:environment)
    Rake.application.rake_require("tasks/categorisation_accounts", [Rails.root.join("lib").to_s])
    task.reenable
    allow(TradeTariffDevHub).to receive(:environment).and_return("development")
    allow(TradeTariff::CreateCategorisationAccount).to receive(:new).and_return(service)
    allow(service).to receive(:call).and_return(result)
  end

  it "creates an account and key after the operator confirms the email address", :aggregate_failures do
    allow($stdin).to receive(:gets).and_return("yes\n")

    expect { task.invoke(email_address) }
      .to output(/Environment: development.*Email: consumer@example\.com.*Continue\? \[y\/N\].*account and Categorisation API key created.*Email: consumer@example\.com.*Client ID: client-123.*Client secret: secret-once-only/m).to_stdout

    expect(service).to have_received(:call).with(email_address)
  end

  it "accepts y as confirmation" do
    allow($stdin).to receive(:gets).and_return("y\n")

    expect { task.invoke(email_address) }.to output(/account and Categorisation API key created/).to_stdout
  end

  it "defaults to no when the operator presses Enter", :aggregate_failures do
    allow($stdin).to receive(:gets).and_return("\n")

    expect { task.invoke(email_address) }
      .to output(/Environment: development.*Continue\? \[y\/N\]/m).to_stdout
      .and output(/Creation cancelled/).to_stderr
      .and raise_error(SystemExit, /Creation cancelled/)
    expect(service).not_to have_received(:call)
  end

  it "defaults to no when input is unavailable", :aggregate_failures do
    allow($stdin).to receive(:gets).and_return(nil)

    expect { task.invoke(email_address) }
      .to output(/Environment: development.*Continue\? \[y\/N\]/m).to_stdout
      .and output(/Creation cancelled/).to_stderr
      .and raise_error(SystemExit, /Creation cancelled/)
    expect(service).not_to have_received(:call)
  end

  it "cancels when the operator enters no", :aggregate_failures do
    allow($stdin).to receive(:gets).and_return("no\n")

    expect { task.invoke(email_address) }
      .to output(/Environment: development.*Continue\? \[y\/N\]/m).to_stdout
      .and output(/Creation cancelled/).to_stderr
      .and raise_error(SystemExit, /Creation cancelled/)
    expect(service).not_to have_received(:call)
  end

  it "requires an email address", :aggregate_failures do
    expect { task.invoke }
      .to output(/Email address is required/).to_stderr
      .and raise_error(SystemExit, /Email address is required/)
    expect(service).not_to have_received(:call)
  end
end
