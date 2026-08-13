# frozen_string_literal: true

class TradeTariff::CreateCategorisationKey
  DESCRIPTION = "Categorisation API key"
  SCOPES = %w[categorisation].freeze

  def initialize(key_creator: nil)
    @key_creator = key_creator || TradeTariff::CreateTradeTariffKey.new
  end

  def call(organisation)
    raise ArgumentError, "Organisation must be persisted" unless organisation&.persisted?
    raise ArgumentError, "Organisation already has an active categorisation key" if active_key?(organisation)

    @key_creator.call(
      organisation.id,
      DESCRIPTION,
      SCOPES,
      usage_plan_id: categorisation_usage_plan_id,
    )
  end

private

  def active_key?(organisation)
    organisation.trade_tariff_keys.active.where("scopes @> ?", SCOPES.to_json).exists?
  end

  def categorisation_usage_plan_id
    TradeTariffDevHub.categorisation_usage_plan_id.presence ||
      raise(ArgumentError, "CATEGORISATION_USAGE_PLAN_ID is not configured")
  end
end
