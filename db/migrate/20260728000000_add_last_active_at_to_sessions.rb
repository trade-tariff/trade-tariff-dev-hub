class AddLastActiveAtToSessions < ActiveRecord::Migration[8.1]
  def change
    add_column :sessions, :last_active_at, :datetime

    # Backfill existing rows: treat updated_at as last activity, created_at + 4h as expiry
    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE sessions
          SET last_active_at = updated_at,
              expires_at     = created_at + INTERVAL '4 hours'
          WHERE last_active_at IS NULL
        SQL
      end
    end
  end
end
