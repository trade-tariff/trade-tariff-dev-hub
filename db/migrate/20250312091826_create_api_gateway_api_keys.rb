class CreateApiGatewayApiKeys < ActiveRecord::Migration[8.0]
  def change
    create_table :api_gateway_api_keys, id: :uuid do |t|
      t.belongs_to :organisation, null: false, foreign_key: true, type: :uuid
      t.string :api_key_id, null: false
      t.string :api_gateway_id, null: false
      t.boolean :enabled
      t.string :secret, null: false
      t.string :usage_plan_id, null: false

      t.timestamps
    end
  end
end
