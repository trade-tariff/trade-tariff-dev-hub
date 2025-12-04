class RenameOttKeysToTradeTariffKeys < ActiveRecord::Migration[8.0]
  def up
    # Skip if table has already been renamed (for local environments that already ran the change)
    return if table_exists?(:trade_tariff_keys) && !table_exists?(:ott_keys)

    # Rename the table (this preserves all data, indexes, and foreign keys)
    rename_table :ott_keys, :trade_tariff_keys

    # Rename the indexes to match the new table name
    if index_exists?(:trade_tariff_keys, :client_id, name: 'index_ott_keys_on_client_id')
      rename_index :trade_tariff_keys, 'index_ott_keys_on_client_id', 'index_trade_tariff_keys_on_client_id'
    end

    if index_exists?(:trade_tariff_keys, :organisation_id, name: 'index_ott_keys_on_organisation_id')
      rename_index :trade_tariff_keys, 'index_ott_keys_on_organisation_id', 'index_trade_tariff_keys_on_organisation_id'
    end

    # Rename foreign key constraint if it exists
    # Find the actual constraint name first
    constraint_name = connection.foreign_keys(:trade_tariff_keys)
                                .find { |fk| fk.column == 'organisation_id' }
                                &.name

    if constraint_name && constraint_name.include?('ott_keys')
      new_constraint_name = constraint_name.sub('ott_keys', 'trade_tariff_keys')
      execute "ALTER TABLE trade_tariff_keys RENAME CONSTRAINT #{connection.quote_column_name(constraint_name)} TO #{connection.quote_column_name(new_constraint_name)}"
    end
  end

  def down
    # Skip if table has already been renamed back
    return if table_exists?(:ott_keys) && !table_exists?(:trade_tariff_keys)

    # Rename indexes back
    if index_exists?(:trade_tariff_keys, :client_id, name: 'index_trade_tariff_keys_on_client_id')
      rename_index :trade_tariff_keys, 'index_trade_tariff_keys_on_client_id', 'index_ott_keys_on_client_id'
    end

    if index_exists?(:trade_tariff_keys, :organisation_id, name: 'index_trade_tariff_keys_on_organisation_id')
      rename_index :trade_tariff_keys, 'index_trade_tariff_keys_on_organisation_id', 'index_ott_keys_on_organisation_id'
    end

    # Rename the table back
    rename_table :trade_tariff_keys, :ott_keys

    # Rename foreign key back
    constraint_name = connection.foreign_keys(:ott_keys)
                                .find { |fk| fk.column == 'organisation_id' }
                                &.name

    if constraint_name && constraint_name.include?('trade_tariff_keys')
      new_constraint_name = constraint_name.sub('trade_tariff_keys', 'ott_keys')
      execute "ALTER TABLE ott_keys RENAME CONSTRAINT #{connection.quote_column_name(constraint_name)} TO #{connection.quote_column_name(new_constraint_name)}"
    end
  end
end
