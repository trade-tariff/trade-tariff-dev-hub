# frozen_string_literal: true

class AddRevokedAtToTradeTariffKeys < ActiveRecord::Migration[8.0]
  def change
    add_column :trade_tariff_keys, :revoked_at, :datetime
  end
end
