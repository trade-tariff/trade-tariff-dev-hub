class OrganisationRole < ApplicationRecord
  self.table_name = "organisations_roles"

  belongs_to :organisation
  belongs_to :role

  has_paper_trail
end
