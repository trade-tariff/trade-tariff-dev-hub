class CreateApiGatewayApiKeys < ActiveRecord::Migration[8.0]
  def change
    create_table :api_gateway_api_keys do |t|
      t.references :organisations, null: false, foreign_key: true
      t.string :api_key_id, null: false
      t.string :api_gateway_id, null: false
      t.boolean :enabled
      t.string :secret, null: false
      t.string :usage_plan_id, null: false

      t.timestamps
    end
  end
end
