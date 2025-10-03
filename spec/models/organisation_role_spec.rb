# == Schema Information
#
# Table name: organisations_roles
#
#  organisation_id :uuid             not null
#  role_id         :uuid             not null
#
# Indexes
#
#  index_organisations_roles_on_organisation_id              (organisation_id)
#  index_organisations_roles_on_organisation_id_and_role_id  (organisation_id,role_id) UNIQUE
#  index_organisations_roles_on_role_id                      (role_id)
#

RSpec.describe OrganisationRole, type: :model do
  it { expect(PaperTrail.request).to be_enabled_for_model(described_class) }
end
