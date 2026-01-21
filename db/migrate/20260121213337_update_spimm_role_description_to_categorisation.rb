class UpdateSpimmRoleDescriptionToCategorisation < ActiveRecord::Migration[8.0]
  def up
    spimm_role = Role.find_by(name: "spimm:full")
    if spimm_role
      spimm_role.update!(description: "Full access to Categorisation API keys.")
    end
  end

  def down
    spimm_role = Role.find_by(name: "spimm:full")
    if spimm_role
      spimm_role.update!(description: "Full access to SPIMM (Simplified Process for Internal Market Movements) API keys.")
    end
  end
end
