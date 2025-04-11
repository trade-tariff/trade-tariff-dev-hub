require "rails_helper"

RSpec.describe ApiKeysController, type: :controller do
  describe "GET #index" do
    ApiKey.all

    it "returns a list of api keys" do
      get :index
      expect(response).to be_successful
    end
  end

  describe "GET #new" do
    it "renders 'new' template" do
      get :new
      expect(response).to be_successful
      expect(response).to render_template("new")
    end
  end

  describe "GET #show" do
    context "When success is set" do
      it "renders 'create' template" do
        get :show, params: { success: true }

        expect(response).to be_successful
        expect(response).to render_template("create")
      end
    end

    context "When success is missing" do
      it "redirects to error page" do
        get :show

        expect(response).not_to be_successful
        expect(response).to redirect_to(not_found_path)
      end
    end
  end

  describe "GET #update" do
    let(:api_key) { create(:api_key) }

    context "Api key is enabled" do
      it "renders 'revoke' template" do
        get :update, params: { id: api_key.id }

        expect(response).to be_successful
        expect(response).to render_template("revoke")
      end
    end

    context "Api key is disabled" do
      it "renders 'delete' template" do
        api_key.update(enabled: false)

        get :update, params: { id: api_key.id }

        expect(response).to be_successful
        expect(response).to render_template("delete")
      end
    end
  end

  describe "POST #create" do
    let(:api_key) { double("API Key", api_key_id: "abc123") }

    before do
      allow(CreateApiKey).to receive(:new).and_return(double(call: api_key))
    end

    it "stores api_key_id in session and redirects" do
      post :create, params: { id: "some-id", description: "test desc" }

      expect(session[:api_key_id]).to eq("abc123")
      expect(response).to redirect_to(api_keys_show_path(success: true))
    end
  end

  describe "PATCH #revoke" do
    let(:api_key) { create(:api_key) }

    before do
      allow(RevokeApiKey).to receive(:new).and_return(double(call: true))
    end

    it "revokes api key and redirects" do
      post :revoke, params: { id: api_key.id }

      expect(response).to redirect_to(api_keys_path)
    end
  end

  describe "DELETE #delete" do
    let(:api_key) { create(:api_key) }

    before do
      allow(DeleteApiKey).to receive(:new).and_return(double(call: true))
    end

    it "deletes api key and redirects" do
      post :delete, params: { id: api_key.id }

      expect(response).to redirect_to(api_keys_path)
    end
  end
end
