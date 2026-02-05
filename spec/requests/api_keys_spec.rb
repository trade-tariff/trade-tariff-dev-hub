RSpec.describe "ApiKeys", type: :request do
  include_context "with authenticated user"

  before do
    current_user.organisation.assign_role!("fpo:full")
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
      let(:created_api_key) { build_stubbed(:api_key, organisation: current_user.organisation) }

      before do
        create_list(:api_key, 2, organisation: current_user.organisation, enabled: true)
        create(:api_key, organisation: current_user.organisation, enabled: false)

        allow(CreateApiKey).to receive(:new).and_return(create_service)
        allow(create_service).to receive(:call).and_return(created_api_key)
      end

      it "allows creating a new key", :aggregate_failures do
        post api_keys_path, params: { api_key: { description: "New key" } }

        expect(response).to render_template("create")
        expect(create_service).to have_received(:call).with(an_instance_of(ApiKey))
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
end
