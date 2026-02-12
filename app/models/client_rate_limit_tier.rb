# == Schema Information
#
# Table name: client_rate_limit_tiers
#
#  id              :uuid             not null, primary key
#  name            :text             not null
#  refill_rate     :integer          not null
#  refill_interval :integer          default(60), not null
#  refill_max      :integer          not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_client_rate_limit_tiers_on_name  (name) UNIQUE
#

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
