class CreateRoleRequests < ActiveRecord::Migration[8.0]
  def change
    create_enum :role_request_status, [
      "pending",
      "approved",
      "rejected",
    ]
    create_table :role_requests, id: :uuid do |t|
      t.references :organisation, null: false, foreign_key: true, type: :uuid
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :role_name, null: false
      t.text :note
      t.enum :status, default: "pending", enum_type: "role_request_status", null: false

      t.timestamps
    end

    add_index :role_requests, [:organisation_id, :role_name, :status],
              name: "index_role_requests_on_org_role_status"
  end
end
