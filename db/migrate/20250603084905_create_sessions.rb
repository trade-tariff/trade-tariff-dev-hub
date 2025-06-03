class CreateSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :sessions, id: :uuid do |t|
      # Session token to validate sessions server-side and prevent replay attacks
      t.string :token, null: false, index: { unique: true }

      t.references :user, null: false, foreign_key: true, type: :uuid
      t.datetime :expires_at, null: false
      t.jsonb :raw_info, null: false

      t.timestamps
    end
  end
end
