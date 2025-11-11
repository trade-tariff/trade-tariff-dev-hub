RSpec.describe ClientRateLimitTier, type: :model do
  describe "validations" do
    subject(:client_rate_limit_tier) { build(:client_rate_limit_tier) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }

    it { is_expected.to validate_presence_of(:refill_rate) }
    it { is_expected.to validate_numericality_of(:refill_rate).only_integer.is_greater_than(0).is_less_than_or_equal_to(2500) }

    it { is_expected.to validate_presence_of(:refill_interval) }
    it { is_expected.to validate_numericality_of(:refill_interval).only_integer.is_greater_than(0).is_less_than_or_equal_to(86_400) }

    it { is_expected.to validate_presence_of(:refill_max) }
    it { is_expected.to validate_numericality_of(:refill_max).only_integer.is_greater_than(0).is_less_than_or_equal_to(2500) }
  end
end
