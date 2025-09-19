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
          'admin',
          'Full access to all features and settings of all organisations',
          NOW(),
          NOW()
        ),
        (
          gen_random_uuid(),
          'fpo:full',
          'Full access to manage FPO (Fast Parcel Operator) API keys',
          NOW(),
          NOW()
        ),
        (
          gen_random_uuid(),
          'ott:full',
          'Full access to manage Online Trade Tariff API keys',
          NOW(),
          NOW()
        ),
        (
          gen_random_uuid(),
          'spimm:full',
          'Full access to manage SPIMM (Simplified Process for Internal Market Movements) API keys',
          NOW(),
          NOW()
        );
    SQL
  end

  def down
    drop_table :roles
  end
end
