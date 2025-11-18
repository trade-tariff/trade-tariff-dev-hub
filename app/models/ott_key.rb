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
#  enabled         :boolean          default("true"), not null
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
  attribute :enabled, :boolean, default: true
  scope :active, -> { where(enabled: true) }

  validate :limit_keys_per_organisation

  def delete_completely!
    Ott::DeleteOttKey.new.call(self)
  end

  def revoke!
    update!(enabled: false)
  end

  def active?
    enabled?
  end

  def revoked?
    !enabled?
  end

private

  def limit_keys_per_organisation
    return if organisation.nil?

    existing_count = organisation.ott_keys.count
    existing_count -= 1 if persisted? # Don't count self if updating

    if existing_count >= 3
      errors.add(:base, "Organisation can have a maximum of 3 OTT keys")
    end
  end
end
