class CreateOttKeys < ActiveRecord::Migration[8.0]
  def change
    create_table :ott_keys, id: :uuid do |t|
      t.string :client_id, null: false
      t.string :secret, null: false
      t.jsonb :scopes, default: []
      t.references :organisation, null: false, foreign_key: true, type: :uuid
      t.text :description

      t.timestamps
    end

    add_index :ott_keys, :client_id, unique: true
  end
end
