RSpec.describe "Admin::Organisations", type: :request do
  include_context "with authenticated user"

  let(:admin_organisation) { create(:organisation, :admin) }
  let(:current_user) { create(:user, organisation: admin_organisation) }
  let(:other_organisation) { create(:organisation) }

  describe "GET /admin/organisations" do
    it "filters organisations by a case-insensitive partial name", :aggregate_failures do
      matching_org = create(:organisation, organisation_name: "Acme Importers")
      create(:organisation, organisation_name: "Delta Services")

      get admin_organisations_path, params: { q: "acme" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(matching_org.organisation_name)
      expect(response.body).not_to include("Delta Services")
      expect(response.body).to include('value="acme"')
    end

    it "falls back to default sort when sort params are invalid", :aggregate_failures do
      older_org = create(:organisation, organisation_name: "Older Org", created_at: 2.days.ago)
      newer_org = create(:organisation, organisation_name: "Newer Org", created_at: 1.day.ago)

      get admin_organisations_path, params: { sort: "unsafe", direction: "sideways" }

      expect(response).to have_http_status(:ok)
      expect(response.body.index(newer_org.organisation_name)).to be < response.body.index(older_org.organisation_name)
      expect(response.body).to include("direction=asc&amp;sort=name")
      expect(response.body).to include("direction=asc&amp;sort=created_at")
    end

    it "preserves search and sorting parameters in pagination links", :aggregate_failures do
      (TradeTariffDevHub::ADMIN_PAGY_PAGE_SIZE + 1).times do |index|
        create(:organisation, organisation_name: "Acme #{index}")
      end

      get admin_organisations_path, params: { q: "Acme", sort: "name", direction: "asc" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to match(
        %r{href="[^"]*\?(?=[^"]*q=Acme)(?=[^"]*sort=name)(?=[^"]*direction=asc)(?=[^"]*page=2)[^"]*"},
      )
    end
  end

  describe "GET /admin/organisations/:id" do
    it "renders GOV.UK back link to organisations index", :aggregate_failures do
      get admin_organisation_path(other_organisation)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('class="govuk-back-link"')
      expect(response.body).to include("href=\"#{admin_organisations_path}\"")
    end
  end
end
