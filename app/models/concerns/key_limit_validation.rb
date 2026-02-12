# frozen_string_literal: true

module KeyLimitValidation
  extend ActiveSupport::Concern

  MAX_KEYS_PER_ORGANISATION = 3

  included do
    validate :limit_keys_per_organisation
  end

private

  def limit_keys_per_organisation
    return if organisation.nil?
    return unless enabled? # Skip validation when key is disabled (only limit active keys)
    return unless TradeTariffDevHub.production_environment? # Skip limit in development/test
    return if organisation.admin? # Skip limit for admin organisations

    # Count only active (non-revoked) keys so revoked keys don't block creating new ones
    existing_count = organisation.send(association_name).active.count
    existing_count -= 1 if persisted? && (respond_to?(:enabled_in_database) ? enabled_in_database : true)

    if existing_count >= MAX_KEYS_PER_ORGANISATION
      errors.add(:base, "Organisation can have a maximum of #{MAX_KEYS_PER_ORGANISATION} active #{key_type_name}")
    end
  end

  def association_name
    raise NotImplementedError, "Subclasses must implement association_name"
  end

  def key_type_name
    raise NotImplementedError, "Subclasses must implement key_type_name"
  end
end
