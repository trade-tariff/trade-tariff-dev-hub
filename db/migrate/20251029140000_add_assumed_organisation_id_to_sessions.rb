class AddAssumedOrganisationIdToSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :sessions, :assumed_organisation_id, :uuid, null: true
    add_foreign_key :sessions, :organisations, column: :assumed_organisation_id
    add_index :sessions, :assumed_organisation_id
  end
end
