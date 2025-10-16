class CreateInvitations < ActiveRecord::Migration[8.0]
  def change
    create_enum :invitation_status, ["pending", "accepted", "declined", "expired", "revoked"]
    create_table :invitations, id: :uuid do |t|
      t.string :invitee_email, null: false
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :organisation, null: false, foreign_key: true, type: :uuid
      t.enum :status, default: "pending", enum_type: "invitation_status", null: false

      t.timestamps
    end

    add_index :invitations, :invitee_email, unique: true
  end
end
