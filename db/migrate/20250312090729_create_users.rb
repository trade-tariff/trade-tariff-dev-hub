class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.belongs_to :organisations, null: false, foreign_key: true
      t.string :email_address
      t.string :user_id, null: false

      t.timestamps
    end
  end
end
