class CreateRoles < ActiveRecord::Migration[8.0]
  def up
    create_table :roles, id: :uuid do |t|
      t.string :name, null: false, index: { unique: true }
      t.string :description, null: false
      t.timestamps
    end

    execute <<-SQL
      INSERT INTO roles (id, name, description, created_at, updated_at)
      VALUES
        (
          gen_random_uuid(),
          'admin:full',
          'Full access to all features and settings. Typically used to manage organisations, their users, roles and API keys.',
          NOW(),
          NOW()
        ),
        (
          gen_random_uuid(),
          'fpo:read',
          'Read-only access to FPO (Fast Parcel Operator) APIs via managed API keys. Preexisting organisations and their users will be assigned this role.',
          NOW(),
          NOW()
        ),
        (
          gen_random_uuid(),
          'standard:read',
          'Read-only access to Standard APIs via managed API keys. This will be the default role assigned to new organisations.',
          NOW(),
          NOW()
        ),
        (
          gen_random_uuid(),
          'spimm:read',
          'Read-only access to SPIMM (Simplified Process for Internal Market Movements) APIs via managed API keys.',
          NOW(),
          NOW()
        );
    SQL
  end

  def down
    drop_table :roles
  end
end
