class CreateOrganisations < ActiveRecord::Migration[8.0]
  def change
    create_table :organisations, id: :uuid do |t|
      t.string :organisation_id, null: false
      t.string :application_reference
      t.string :description
      t.string :eori_number
      t.string :organisation_name
      t.integer :status
      t.string :uk_acs_reference

      t.timestamps
    end
  end
end
