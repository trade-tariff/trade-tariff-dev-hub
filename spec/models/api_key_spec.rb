require "rails_helper"

RSpec.describe ApiKey, type: :model do
  it { expect(PaperTrail.request).to be_enabled_for_model(described_class) }
end
