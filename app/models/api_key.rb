# == Schema Information
#
# Table name: api_keys
#
#  id              :uuid             not null, primary key
#  organisation_id :uuid             not null
#  api_key_id      :string           not null
#  api_gateway_id  :string           not null
#  enabled         :boolean
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

  def delete_completely!
    DeleteApiKey.new.call(self)
  end
end
