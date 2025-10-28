class AddEnabledAndDescriptionToOttKeys < ActiveRecord::Migration[8.0]
  def change
    add_column :ott_keys, :enabled, :boolean
    add_column :ott_keys, :description, :text
  end
end
