# == Schema Information
#
# Table name: trade_tariff_keys
#
#  id              :uuid             not null, primary key
#  client_id       :string           not null
#  scopes          :jsonb            default("[]")
#  organisation_id :uuid             not null
#  description     :text
#  enabled         :boolean          default(TRUE), not null
#  revoked_at      :datetime
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

  # Scopes that exist on a key but must never be shown in the Dev Portal UI,
  # e.g. because the key was provisioned directly from the backend outside
  # any self-service flow.
  HIDDEN_SCOPES = %w[categorisation].freeze

  has_paper_trail

  belongs_to :organisation

  validates :client_id, presence: true, uniqueness: true
  validates :scopes, presence: true, length: { minimum: 1 }
  attribute :enabled, :boolean, default: true
  scope :active, -> { where(enabled: true) }

  def revoke!
    update!(enabled: false, revoked_at: Time.current)
  end

  def visible_scopes
    scopes - HIDDEN_SCOPES
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
