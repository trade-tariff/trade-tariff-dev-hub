class User < ApplicationRecord
  has_paper_trail

  belongs_to :organisations
end
