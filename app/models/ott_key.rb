# == Schema Information
#
# Table name: ott_keys
#
#  id              :uuid             not null, primary key
#  client_id       :string           not null
#  secret          :string           not null
#  scopes          :jsonb            default("[]")
#  organisation_id :uuid             not null
#  description     :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_ott_keys_on_client_id        (client_id) UNIQUE
#  index_ott_keys_on_organisation_id  (organisation_id)
#

class OttKey < ApplicationRecord
  has_paper_trail

  belongs_to :organisation

  validates :client_id, presence: true, uniqueness: true
  validates :secret, presence: true
  validates :scopes, presence: true, length: { minimum: 1 }

  def delete_completely!
    Ott::DeleteOttKey.new.call(self)
  end
end
