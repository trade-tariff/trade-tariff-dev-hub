RSpec.describe "Organisations", type: :request do
  include_context "with authenticated user"

  describe "GET /organisations" do
    it "redirects to the current user's organisation page" do
      get organisations_path
      expect(response).to redirect_to(organisation_path(current_user.organisation))
    end
  end

  describe "GET /organisations/:id" do
    it "renders the organisation page", :aggregate_failures do
      get organisation_path(current_user.organisation)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(current_user.organisation.organisation_name)
    end

    context "when accessing another organisation as a non-admin user" do
      let(:other_organisation) { create(:organisation) }

      it "redirects to the current user's organisation page" do
        get organisation_path(other_organisation)
        expect(response).to redirect_to(organisation_path(current_user.organisation))
      end
    end

    context "when accessing another organisation as an admin user" do
      let(:current_user) { create(:user, organisation: create(:organisation, :admin)) }
      let(:other_organisation) { create(:organisation) }

      it "renders the other organisation's page", :aggregate_failures do
        get organisation_path(other_organisation)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(other_organisation.organisation_name)
      end
    end
  end

  describe "GET /organisations/:id/edit" do
    it "renders the edit organisation form", :aggregate_failures do
      get edit_organisation_path(current_user.organisation)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("action=\"#{organisation_path(current_user.organisation)}\"")
      expect(response.body).to include('method="post"')
      expect(response.body).to include('name="organisation[organisation_name]"')
    end
  end

  describe "PATCH /organisations/:id" do
    context "with valid parameters" do
      let(:new_name) { "New Organisation Name" }
      let(:params) { { organisation: { organisation_name: new_name } } }

      it "updates the organisation and redirects to the organisation page with a notice", :aggregate_failures do
        patch organisation_path(current_user.organisation), params: params
        expect(response).to redirect_to(organisation_path(current_user.organisation))
        follow_redirect!
        expect(response.body).to include("Organisation updated")
        expect(current_user.organisation.reload.organisation_name).to eq(new_name)
      end
    end

    context "with invalid parameters" do
      let(:params) { { organisation: { organisation_name: "" } } }

      it "does not update the organisation and re-renders the edit template with errors", :aggregate_failures do
        patch organisation_path(current_user.organisation), params: params
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Enter an organisation name")
        expect(current_user.organisation.reload.organisation_name).not_to eq("")
      end
    end
  end
end
