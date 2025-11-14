# == Schema Information
#
# Table name: api_keys
#
#  id              :uuid             not null, primary key
#  organisation_id :uuid             not null
#  api_key_id      :string           not null
#  api_gateway_id  :string           not null
#  enabled         :boolean          default("true")
#  secret          :string           not null
#  usage_plan_id   :string           not null
#  description     :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_api_keys_on_api_key_id_and_organisation_id  (api_key_id,organisation_id) UNIQUE
#  index_api_keys_on_organisation_id                 (organisation_id)
#

class ApiKey < ApplicationRecord
  has_paper_trail

  belongs_to :organisation

  scope :active, -> { where(enabled: true) }

  validate :limit_keys_per_organisation

  def delete_completely!
    DeleteApiKey.new.call(self)
  end

private

  def limit_keys_per_organisation
    return if organisation.nil?

    existing_count = organisation.api_keys.count
    existing_count -= 1 if persisted? # Don't count self if updating

    if existing_count >= 3
      errors.add(:base, "Organisation can have a maximum of 3 API keys")
    end
  end
end
