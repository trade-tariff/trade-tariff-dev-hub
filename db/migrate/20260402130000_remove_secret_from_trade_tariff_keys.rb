# frozen_string_literal: true

class RemoveSecretFromTradeTariffKeys < ActiveRecord::Migration[8.1]
  def change
    remove_column :trade_tariff_keys, :secret, :string
  end
end
