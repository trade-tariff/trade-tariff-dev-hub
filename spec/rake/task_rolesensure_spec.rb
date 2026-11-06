require "rake"

# rubocop:disable RSpec/DescribeMethod
RSpec.describe Rake::Task, "roles:ensure" do
  # rubocop:enable RSpec/DescribeMethod
  subject(:task) { described_class["roles:ensure"] }

  let(:migrate) { described_class["db:migrate"] }

  around do |example|
    original_version = ENV["VERSION"]
    example.run
  ensure
    ENV["VERSION"] = original_version
  end

  before do
    described_class.define_task(:environment)
    described_class.define_task("db:migrate")
    Rake.application.rake_require("tasks/roles", [Rails.root.join("lib").to_s], [])
    task.reenable
    migrate.reenable
    Role.delete_all
  end

  it "creates the default roles" do
    task.invoke

    expect(Role.pluck(:name)).to match_array(Role::DEFAULT_ROLES.keys)
  end

  it "does not change a role that exists", :aggregate_failures do
    role = create(:role, name: Role::ADMIN_ROLE_NAME, description: "Edited")

    task.invoke
    task.reenable
    task.invoke

    expect(Role.count).to eq(Role::DEFAULT_ROLES.size)
    expect(role.reload.description).to eq("Edited")
  end

  it "runs after db:migrate" do
    migrate.invoke

    expect(Role.count).to eq(Role::DEFAULT_ROLES.size)
  end

  it "does not run after db:migrate with a VERSION" do
    ENV["VERSION"] = "20250918072903"
    migrate.invoke

    expect(Role.count).to eq(0)
  end
end
