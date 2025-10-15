class AddEnabledToOttKeys < ActiveRecord::Migration[8.0]
  def change
    add_column :ott_keys, :enabled, :boolean, default: true, null: false
  end
end
