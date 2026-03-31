class RemoveSpimmFullRole < ActiveRecord::Migration[8.0]
  SPIMM_ROLE_NAME = "spimm:full"

  def up
    role = Role.find_by(name: SPIMM_ROLE_NAME)
    return unless role

    role.organisations.clear
    RoleRequest.where(role_name: SPIMM_ROLE_NAME).delete_all
    role.destroy!
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
