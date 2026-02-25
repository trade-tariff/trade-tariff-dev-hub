# == Schema Information
#
# Table name: trade_tariff_keys
#
#  id              :uuid             not null, primary key
#  client_id       :string           not null
#  secret          :string
#  scopes          :jsonb            default("[]")
#  organisation_id :uuid             not null
#  description     :text
#  enabled         :boolean          default(TRUE), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  api_gateway_id  :string
#  usage_plan_id   :string
#
# Indexes
#
#  index_trade_tariff_keys_on_client_id        (client_id) UNIQUE
#  index_trade_tariff_keys_on_organisation_id  (organisation_id)
#

class TradeTariffKey < ApplicationRecord
  include KeyLimitValidation

  has_paper_trail

  belongs_to :organisation

  validates :client_id, presence: true, uniqueness: true
  validates :scopes, presence: true, length: { minimum: 1 }
  attribute :enabled, :boolean, default: true
  scope :active, -> { where(enabled: true) }

  def delete_completely!
    TradeTariff::DeleteTradeTariffKey.new.call(self)
  end

  def revoke!
    update!(enabled: false)
  end

  def active?
    enabled?
  end

  def revoked?
    !enabled?
  end

private

  def association_name
    :trade_tariff_keys
  end

  def key_type_name
    "Trade Tariff keys"
  end
end
