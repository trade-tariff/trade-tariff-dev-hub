class HashExistingSessionTokens < ActiveRecord::Migration[8.0]
  def up
    Session.find_each do |session|
      session.update_coluhn(:token, Digest::SHA256.hexdigest(session.token))
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
