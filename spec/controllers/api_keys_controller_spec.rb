RSpec.describe ApiKeysController, type: :controller do
  include_context "with authenticated user"

  before do
    current_user.organisation.assign_role!("fpo:full")
  end

  shared_examples_for "an unauthorised user" do
    context "when user does not have required role" do
      before do
        current_user.organisation.unassign_role!("fpo:full")
      end

      it "redirects to root path" do
        get :index
        expect(response).to redirect_to(root_path)
      end

      it "sets a flash alert message" do
        get :index
        expect(flash[:alert]).to match("does not have the required permissions to access this section")
      end
    end
  end

  describe "GET #index" do
    subject! { get :index }

    it "returns a list of api keys" do
      expect(response).to be_successful
    end

    include_examples "an unauthorised user"
  end

  describe "GET #new" do
    subject! { get :new }

    it "renders 'new' template" do
      expect(response).to render_template("new")
    end

    it "is successful" do
      expect(response).to be_successful
    end

    include_examples "an unauthorised user"
  end

  describe "GET #update" do
    subject(:do_action) { get :update, params: { id: api_key.id } }

    let(:api_key) { create(:api_key, organisation: current_user.organisation) }

    context "when api key is enabled" do
      it "renders 'revoke' template" do
        do_action
        expect(response).to render_template("revoke")
      end

      it "is successful" do
        do_action
        expect(response).to be_successful
      end
    end

    context "when api key is disabled" do
      before do
        api_key.update!(enabled: false)
        do_action
      end

      it "renders 'delete' template" do
        expect(response).to render_template("delete")
      end

      it "is successful" do
        expect(response).to be_successful
      end
    end

    include_examples "an unauthorised user"
  end

  describe "POST #create" do
    subject(:do_action) { post :create, params: { id: "some-id", description: "test desc" } }

    let(:api_key) { create(:api_key, api_key_id: "abc123", organisation: current_user.organisation) }
    let(:service) { instance_double(CreateApiKey, call: api_key) }

    before do
      allow(CreateApiKey).to receive(:new).and_return(service)
    end

    it "renders the create template" do
      post :create, params: { id: "some-id", description: "test desc" }
      expect(response).to render_template("create")
    end

    include_examples "an unauthorised user"
  end

  describe "PATCH #revoke" do
    subject(:do_action) { post :revoke, params: { id: api_key.id } }

    let(:api_key) { create(:api_key, organisation: current_user.organisation) }
    let(:service) { instance_double(RevokeApiKey, call: true) }

    before do
      allow(RevokeApiKey).to receive(:new).and_return(service)
      do_action
    end

    it "revokes api key and redirects" do
      expect(response).to redirect_to(api_keys_path)
    end

    include_examples "an unauthorised user"
  end

  describe "DELETE #delete" do
    subject(:do_action) { post :delete, params: { id: api_key.id } }

    let(:api_key) { create(:api_key, organisation: current_user.organisation) }
    let(:service) { instance_double(DeleteApiKey, call: true) }

    before do
      allow(DeleteApiKey).to receive(:new).and_return(service)
      do_action
    end

    it "deletes api key and redirects" do
      expect(response).to redirect_to(api_keys_path)
    end

    include_examples "an unauthorised user"
  end
end
