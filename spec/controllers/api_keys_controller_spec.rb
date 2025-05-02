require "rails_helper"

RSpec.describe ApiKeysController, type: :controller do
  before { session[:organisation_id] = organisation.id }

  let(:organisation) { create(:organisation, organisation_id: "local-development") }

  describe "GET #index" do
    it "returns a list of api keys" do
      get :index
      expect(response).to be_successful
    end
  end

  describe "GET #new" do
    it "renders 'new' template" do
      get :new
      expect(response).to render_template("new")
    end

    it "is successful" do
      get :new
      expect(response).to be_successful
    end
  end

  describe "GET #update" do
    let(:api_key) { create(:api_key, organisation:) }

    context "when api key is enabled" do
      it "renders 'revoke' template" do
        get :update, params: { id: api_key.id }

        expect(response).to render_template("revoke")
      end

      it "is successful" do
        get :update, params: { id: api_key.id }
        expect(response).to be_successful
      end
    end

    context "when api key is disabled" do
      before do
        api_key.update!(enabled: false)
      end

      it "renders 'delete' template" do
        get :update, params: { id: api_key.id }
        expect(response).to render_template("delete")
      end

      it "is successful" do
        get :update, params: { id: api_key.id }
        expect(response).to be_successful
      end
    end
  end

  describe "POST #create" do
    let(:api_key) { create(:api_key, api_key_id: "abc123", organisation:) }
    let(:service) { instance_double(CreateApiKey, call: api_key) }

    before do
      allow(CreateApiKey).to receive(:new).and_return(service)
    end

    it "renders the create template" do
      post :create, params: { id: "some-id", description: "test desc" }
      expect(response).to render_template("create")
    end
  end

  describe "PATCH #revoke" do
    let(:api_key) { create(:api_key, organisation: organisation) }
    let(:service) { instance_double(RevokeApiKey, call: true) }

    before do
      allow(RevokeApiKey).to receive(:new).and_return(service)
    end

    it "revokes api key and redirects" do
      post :revoke, params: { id: api_key.id }

      expect(response).to redirect_to(api_keys_path)
    end
  end

  describe "DELETE #delete" do
    let(:api_key) { create(:api_key, organisation:) }
    let(:service) { instance_double(DeleteApiKey, call: true) }

    before do
      allow(DeleteApiKey).to receive(:new).and_return(service)
    end

    it "deletes api key and redirects" do
      post :delete, params: { id: api_key.id }

      expect(response).to redirect_to(api_keys_path)
    end
  end
end
