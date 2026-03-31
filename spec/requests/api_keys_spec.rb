RSpec.describe "ApiKeys", type: :request do
  include_context "with authenticated user"

  before do
    current_user.organisation.assign_role!("fpo:full")
    allow(TradeTariffDevHub).to receive(:live_production_environment?).and_return(true)
  end

  describe "POST /api_keys" do
    context "when organisation has 3 active API keys" do
      before do
        create_list(:api_key, 3, organisation: current_user.organisation, enabled: true)
      end

      it "renders the new form with validation errors", :aggregate_failures do
        post api_keys_path, params: { api_key: { description: "New key" } }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Organisation can have a maximum of 3 active API keys")
      end

      it "displays the error in a GOV.UK error summary", :aggregate_failures do
        post api_keys_path, params: { api_key: { description: "New key" } }

        expect(response.body).to include("govuk-error-summary")
        expect(response.body).to include("There is a problem")
      end

      it "does not create a new API key" do
        expect {
          post api_keys_path, params: { api_key: { description: "New key" } }
        }.not_to change(ApiKey, :count)
      end
    end

    context "when organisation has 2 active and 1 inactive API key" do
      let(:create_service) { instance_double(CreateApiKey) }

      before do
        create_list(:api_key, 2, organisation: current_user.organisation, enabled: true)
        create(:api_key, organisation: current_user.organisation, enabled: false)
        allow(TradeTariffDevHub).to receive(:live_production_environment?).and_return(true)
        allow(CreateApiKey).to receive(:new).and_return(create_service)
        allow(create_service).to receive(:call) do |api_key|
          create(:api_key, organisation: api_key.organisation, description: api_key.description)
        end
      end

      it "allows creating a new key (only active keys count toward the limit)" do
        expect {
          post api_keys_path, params: { api_key: { description: "New key" } }
        }.to change(ApiKey, :count).by(1)
      end
    end
  end

  describe "PATCH /api_keys/:id/revoke" do
    let(:revoke_service) { instance_double(RevokeApiKey) }

    before do
      allow(RevokeApiKey).to receive(:new).and_return(revoke_service)
      allow(revoke_service).to receive(:call)
    end

    context "when organisation has 3 active API keys" do
      let!(:api_keys) { create_list(:api_key, 3, organisation: current_user.organisation, enabled: true) }
      let(:api_key_to_revoke) { api_keys.first }

      it "successfully revokes the key", :aggregate_failures do
        patch revoke_api_key_path(api_key_to_revoke)

        expect(response).to redirect_to(api_keys_path)
        expect(revoke_service).to have_received(:call).with(api_key_to_revoke)
      end

      it "does not fail validation" do
        patch revoke_api_key_path(api_key_to_revoke)

        expect(response).not_to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "POST /api_keys for admin organisations" do
    before do
      current_user.organisation.assign_role!("admin")
      current_user.organisation.assign_role!("fpo:full")
      allow(TradeTariffDevHub).to receive(:live_production_environment?).and_return(true)
    end

    context "when admin organisation has 3 active API keys" do
      let(:create_service) { instance_double(CreateApiKey) }
      let(:created_api_key) { build_stubbed(:api_key, organisation: current_user.organisation) }

      before do
        create_list(:api_key, 3, organisation: current_user.organisation, enabled: true)
        allow(CreateApiKey).to receive(:new).and_return(create_service)
        allow(create_service).to receive(:call).and_return(created_api_key)
      end

      it "allows creating a new key beyond the limit", :aggregate_failures do
        post api_keys_path, params: { api_key: { description: "New key" } }

        expect(response).to render_template("create")
        expect(create_service).to have_received(:call).with(an_instance_of(ApiKey))
      end

      it "does not show validation errors" do
        post api_keys_path, params: { api_key: { description: "New key" } }

        expect(response.body).not_to include("Organisation can have a maximum of 3 active API keys")
      end
    end

    context "when admin organisation has many active API keys" do
      let(:create_service) { instance_double(CreateApiKey) }
      let(:created_api_key) { build_stubbed(:api_key, organisation: current_user.organisation) }

      before do
        create_list(:api_key, 10, organisation: current_user.organisation, enabled: true)
        allow(CreateApiKey).to receive(:new).and_return(create_service)
        allow(create_service).to receive(:call).and_return(created_api_key)
      end

      it "allows creating additional keys", :aggregate_failures do
        post api_keys_path, params: { api_key: { description: "New key" } }

        expect(response).to render_template("create")
        expect(create_service).to have_received(:call).with(an_instance_of(ApiKey))
      end
    end
  end

  describe "GET back-link rendering" do
    it "renders back link on new API key page", :aggregate_failures do
      get new_api_key_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('class="govuk-back-link"')
      expect(response.body).to include("href=\"#{api_keys_path}\"")
    end

    it "renders back link on revoke page", :aggregate_failures do
      active_api_key = create(:api_key, organisation: current_user.organisation, enabled: true)
      get revoke_api_key_path(active_api_key)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('class="govuk-back-link"')
      expect(response.body).to include("href=\"#{api_keys_path}\"")
    end

    it "renders back link on delete page", :aggregate_failures do
      revoked_api_key = create(:api_key, organisation: current_user.organisation, enabled: false)
      get delete_api_key_path(revoked_api_key)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('class="govuk-back-link"')
      expect(response.body).to include("href=\"#{api_keys_path}\"")
    end

    context "when user is an admin accessing another organisation's API key" do
      let(:admin_organisation) { create(:organisation, :admin) }
      let(:current_user) { create(:user, organisation: admin_organisation) }

      let(:other_organisation) { create(:organisation) }

      it "renders admin organisation back link on revoke page", :aggregate_failures do
        other_org_active_api_key = create(:api_key, organisation: other_organisation, enabled: true)
        get revoke_api_key_path(other_org_active_api_key)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('class="govuk-back-link"')
        expect(response.body).to include("href=\"#{admin_organisation_path(other_organisation.id)}\"")
      end

      it "renders admin organisation back link on delete page", :aggregate_failures do
        other_org_revoked_api_key = create(:api_key, organisation: other_organisation, enabled: false)
        get delete_api_key_path(other_org_revoked_api_key)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('class="govuk-back-link"')
        expect(response.body).to include("href=\"#{admin_organisation_path(other_organisation.id)}\"")
      end
    end
  end
end
