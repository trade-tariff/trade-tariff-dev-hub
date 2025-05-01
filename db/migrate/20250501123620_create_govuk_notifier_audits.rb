class CreateGovukNotifierAudits < ActiveRecord::Migration[8.0]
  def change
    create_table :govuk_notifier_audits, id: :uuid do |t|
      t.string :notification_uuid, null: false
      t.string :subject, null: false
      t.string :body, null: false
      t.string :from_email, null: false
      t.string :template_id, null: false
      t.string :template_version, null: false
      t.string :template_uri, null: false
      t.string :notification_uri, null: false

      t.timestamps
    end

    add_index :govuk_notifier_audits, :notification_uuid, unique: true
  end
end
