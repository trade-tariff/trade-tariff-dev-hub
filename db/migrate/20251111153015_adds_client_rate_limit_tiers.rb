class AddsClientRateLimitTiers < ActiveRecord::Migration[8.0]
  def change
    create_table :client_rate_limit_tiers, id: :uuid do |t|
      t.text :name, null: false # A useful name for the tier (e.g. standard)
      t.integer :refill_rate, null: false # Over the interval how many tokens will be refreshed?
      t.integer :refill_interval, null: false, default: 60 # The interval in seconds over which the number of tokens in the refill rate will replenish (e.g. every 60 seconds)
      t.integer :refill_max, null: false # The maximum size of the token bucket for this client (larger numbers enables a burst of requests above the refill rate).

      t.timestamps
    end

    add_index :client_rate_limit_tiers, :name, unique: true
  end
end
