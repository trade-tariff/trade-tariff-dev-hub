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
        expect(flash[:alert]).to match("This service is not yet open to the public. If you have any questions please contact us on hmrc-trade-tariff-support-g@digital.hmrc.gov.uk")
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
    subject(:do_action) { post :create, params: { api_key: { description: "test desc" } } }

    let(:created_api_key) { build(:api_key, organisation: current_user.organisation) }
    let(:service) { instance_double(CreateApiKey) }

    before do
      allow(CreateApiKey).to receive(:new).and_return(service)
      allow(service).to receive(:call).and_return(created_api_key)
    end

    it "renders the create template" do
      do_action
      expect(response).to render_template("create")
    end

    it "calls the service with an ApiKey object" do
      do_action
      expect(service).to have_received(:call).with(an_instance_of(ApiKey))
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
