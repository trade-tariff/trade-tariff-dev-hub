class OttKey < ApplicationRecord
  has_paper_trail

  belongs_to :organisation

  validates :client_id, presence: true, uniqueness: true
  validates :secret, presence: true
  validates :scopes, presence: true

  def delete_completely!
    Ott::DeleteOttKey.new.call(self)
  end
end
