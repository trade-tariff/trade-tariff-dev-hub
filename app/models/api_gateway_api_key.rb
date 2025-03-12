class ApiGatewayApiKey < ApplicationRecord
  has_paper_trail

  belongs_to :organisations
end
