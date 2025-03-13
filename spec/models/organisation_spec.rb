require "rails_helper"

RSpec.describe Organisation, type: :model do
  subject(:organisation) { build(:organisation) }

  let(:expected_enum) do
    {
      unregistered: 0,
      authorised: 1,
      pending: 2,
      rejected: 3,
    }
  end

  it { is_expected.to define_enum_for(:status).with_values(expected_enum) }
  it { expect(PaperTrail.request).to be_enabled_for_model(described_class) }
end
