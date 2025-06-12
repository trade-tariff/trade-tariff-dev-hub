class ApiKey < ApplicationRecord
  has_paper_trail

  belongs_to :organisation

  def delete_completely!
    DeleteApiKey.new.call(self)
  end
end
