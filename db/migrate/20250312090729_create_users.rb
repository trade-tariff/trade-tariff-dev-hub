class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users, id: :uuid do |t|
      t.belongs_to :organisation, null: false, foreign_key: true, type: :uuid
      t.string :email_address
      t.string :user_id, null: false

      t.timestamps
    end

    add_index :users, [:user_id, :organisation_id], unique: true
  end
end
