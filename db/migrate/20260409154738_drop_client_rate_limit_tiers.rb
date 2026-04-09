class DropClientRateLimitTiers < ActiveRecord::Migration[8.1]
  def up
    drop_table :client_rate_limit_tiers
  end

  def down
    create_table :client_rate_limit_tiers, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.text :name, null: false
      t.integer :refill_rate, null: false
      t.integer :refill_interval, null: false, default: 60
      t.integer :refill_max, null: false
      t.timestamps
    end
    add_index :client_rate_limit_tiers, :name, unique: true
  end
end
