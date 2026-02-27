# frozen_string_literal: true

class AddApiGatewayToTradeTariffKeys < ActiveRecord::Migration[8.0]
  def up
    add_column :trade_tariff_keys, :api_gateway_id, :string
    add_column :trade_tariff_keys, :usage_plan_id, :string
    change_column_null :trade_tariff_keys, :secret, true
  end

  def down
    # Rows with NULL secret (Cognito-provisioned keys) cannot exist after reverting to NOT NULL.
    # Remove them so the column constraint can be restored; they can be re-created with real credentials later.
    execute <<-SQL.squish
      DELETE FROM trade_tariff_keys WHERE secret IS NULL
    SQL
    change_column_null :trade_tariff_keys, :secret, false
    remove_column :trade_tariff_keys, :usage_plan_id
    remove_column :trade_tariff_keys, :api_gateway_id
  end
end
