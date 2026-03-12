RSpec.describe "Admin::Organisations", type: :request do
  include_context "with authenticated user"

  let(:admin_organisation) { create(:organisation, :admin) }
  let(:current_user) { create(:user, organisation: admin_organisation) }
  let(:other_organisation) { create(:organisation) }

  describe "GET /admin/organisations/:id" do
    it "renders GOV.UK back link to organisations index", :aggregate_failures do
      get admin_organisation_path(other_organisation)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('class="govuk-back-link"')
      expect(response.body).to include("href=\"#{admin_organisations_path}\"")
    end
  end
end
