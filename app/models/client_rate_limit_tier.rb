class ClientRateLimitTier < ApplicationRecord
  validates :name, presence: true, uniqueness: true

  validates :refill_rate,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than: 0,
              less_than_or_equal_to: 2500,
            }

  validates :refill_interval,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than: 0, # at least 1 second
              less_than_or_equal_to: 86_400, # 24 hours
            }

  validates :refill_max,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than: 0,
              less_than_or_equal_to: 2500,
            }
end
