class CreateOrganisationRoles < ActiveRecord::Migration[8.0]
  def change
    create_table :organisations_roles, id: false do |t|
      t.references :organisation, null: false, foreign_key: true, type: :uuid
      t.references :role, null: false, foreign_key: true, type: :uuid
    end

    add_index :organisations_roles, [:organisation_id, :role_id], unique: true

    Organisation.all.each do |organisation|
      organisation.assign_role!("fpo:full")
      organisation.assign_role!("ott:full")
    end
  end
end
