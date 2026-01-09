class RenameOttRoleToTradeTariffRole < ActiveRecord::Migration[8.0]
  def up
    # Check if ott:full role exists
    ott_role = Role.find_by(name: 'ott:full')

    if ott_role
      # Check if trade_tariff:full already exists (shouldn't happen, but be safe)
      trade_tariff_role = Role.find_by(name: 'trade_tariff:full')

      if trade_tariff_role
        # If both exist, we need to merge them
        # Move all organisation associations from ott:full to trade_tariff:full
        execute <<-SQL
          INSERT INTO organisations_roles (organisation_id, role_id)
          SELECT organisation_id, '#{trade_tariff_role.id}'::uuid
          FROM organisations_roles
          WHERE role_id = '#{ott_role.id}'::uuid
          ON CONFLICT (organisation_id, role_id) DO NOTHING;
        SQL

        # Delete the ott:full role
        ott_role.destroy
      else
        # Simply rename the role
        ott_role.update!(name: 'trade_tariff:full', description: 'Full access to Trade Tariff public API keys')
      end
    end
  end

  def down
    # Check if trade_tariff:full role exists
    trade_tariff_role = Role.find_by(name: 'trade_tariff:full')

    if trade_tariff_role
      # Check if ott:full already exists
      ott_role = Role.find_by(name: 'ott:full')

      if ott_role
        # If both exist, merge them back
        execute <<-SQL
          INSERT INTO organisations_roles (organisation_id, role_id)
          SELECT organisation_id, '#{ott_role.id}'::uuid
          FROM organisations_roles
          WHERE role_id = '#{trade_tariff_role.id}'::uuid
          ON CONFLICT (organisation_id, role_id) DO NOTHING;
        SQL

        # Delete the trade_tariff:full role
        trade_tariff_role.destroy
      else
        # Simply rename back to ott:full
        trade_tariff_role.update!(name: 'ott:full', description: 'Full access to manage Online Trade Tariff API keys')
      end
    end
  end
end
