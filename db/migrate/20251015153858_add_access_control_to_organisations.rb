class AddAccessControlToOrganisations < ActiveRecord::Migration[8.0]
  def change
    add_column :organisations, :fpo_access, :boolean, default: false, null: false
    add_column :organisations, :ott_access, :boolean, default: false, null: false
  end
end
