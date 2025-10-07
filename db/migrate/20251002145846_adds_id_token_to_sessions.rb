class AddsIdTokenToSessions < ActiveRecord::Migration[8.0]
  def up
    Session.delete_all
    add_column :sessions, :id_token, :text, null: false
    change_column :sessions, :raw_info, :jsonb, null: true
    change_column :sessions, :expires_at, :datetime, null: true

    remove_index :organisations, :organisation_id, unique: true
    change_column :organisations, :organisation_id, :string, null: true

    remove_index :users, [:user_id, :organisation_id], unique: true
    add_index :users, [:email_address], unique: true
  end

  def down
    remove_column :sessions, :id_token
    change_column :sessions, :raw_info, :jsonb, null: false
    change_column :sessions, :expires_at, :datetime, null: false

    add_index :organisations, :organisation_id, unique: true
    change_column :organisations, :organisation_id, :string, null: false

    add_index :users, [:user_id, :organisation_id], unique: true
    remove_index :users, [:email_address], unique: true
  end
end
