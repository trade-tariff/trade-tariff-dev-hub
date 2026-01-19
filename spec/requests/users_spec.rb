RSpec.describe "Users", type: :request do
  include_context "with authenticated user"

  describe "GET /users/:id/remove" do
    let(:other_user) { create(:user, email_address: "foo@baz.com", organisation: current_user.organisation) }
    let(:params) { { id: other_user.id } }

    it "renders the remove user confirmation page", :aggregate_failures do
      get remove_user_path(other_user), params: params
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(other_user.email_address)
      expect(response.body).to include("Remove a user from an organisation")
    end

    context "when trying to remove oneself" do
      let(:params) { { id: current_user.id } }

      it "redirects to the organisation page with an alert", :aggregate_failures do
        get remove_user_path(current_user), params: params
        expect(response).to redirect_to(organisation_path(current_user.organisation))
        follow_redirect!
        expect(response.body).to include("You cannot delete your own user account")
      end
    end

    context "when trying to remove a user from another organisation" do
      let!(:other_user) { create(:user, email_address: "foo@baz.com", organisation: other_organisation) }
      let(:other_organisation) { create(:organisation) }
      let(:params) { { id: other_user.id } }

      it "redirects to the organisation page with an alert", :aggregate_failures do
        get remove_user_path(other_user), params: params
        expect(response).to redirect_to(organisation_path(current_user.organisation))
        follow_redirect!
        expect(response.body).to include("You can only delete users from your own organisation.")
      end
    end
  end

  describe "DELETE /users/:id" do
    let(:other_user) { create(:user, email_address: "foo@baz.com", organisation: current_user.organisation) }
    let(:params) { { id: other_user.id } }
    let(:organisation) { current_user.organisation }

    it "deletes the user and redirects to the organisation page with a notice", :aggregate_failures do
      delete user_path(other_user), params: params
      expect(response).to redirect_to(organisation_path(organisation.id))
      follow_redirect!
      expect(response.body).to include("User #{other_user.email_address} has been removed from the organisation.")
      expect(User.where(id: other_user.id)).to be_empty
    end

    context "when trying to delete oneself" do
      let(:params) { { id: current_user.id } }

      it "redirects to the organisation page with an alert and does not delete the user", :aggregate_failures do
        delete user_path(current_user), params: params
        expect(response).to redirect_to(organisation_path(organisation.id))
        follow_redirect!
        expect(response.body).to include("You cannot delete your own user account")
        expect(User.where(id: current_user.id)).to exist
      end
    end

    context "when trying to delete a user from another organisation" do
      let!(:other_user) { create(:user, email_address: "foo@baz.com", organisation: other_organisation) }
      let(:other_organisation) { create(:organisation) }
      let(:params) { { id: other_user.id } }
      let(:organisation) { current_user.organisation }

      it "redirects to the organisation page with an alert and does not delete the user", :aggregate_failures do
        delete user_path(other_user), params: params
        expect(response).to redirect_to(organisation_path(organisation.id))
        follow_redirect!
        expect(response.body).to include("You can only delete users from your own organisation.")
        expect(User.where(id: other_user.id)).to exist
      end
    end
  end
end
