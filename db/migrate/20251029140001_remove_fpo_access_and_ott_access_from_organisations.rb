class RemoveFpoAccessAndOttAccessFromOrganisations < ActiveRecord::Migration[8.0]
  def change
    remove_column :organisations, :fpo_access, :boolean
    remove_column :organisations, :ott_access, :boolean
  end
end
