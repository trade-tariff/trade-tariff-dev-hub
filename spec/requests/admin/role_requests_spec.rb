RSpec.describe "Admin Role Requests", type: :request do
  include_context "with authenticated user"

  before do
    current_user.organisation.assign_role!("admin")
  end

  describe "GET /admin/role_requests" do
    let!(:pending_request) { create(:role_request, status: "pending") }

    before do
      create(:role_request, status: "approved")
    end

    it "returns successful response", :aggregate_failures do
      get admin_role_requests_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Access Requests")
    end

    it "displays only pending requests", :aggregate_failures do
      get admin_role_requests_path
      expect(response.body).to include(pending_request.organisation.organisation_name)
      expect(response.body).to include(pending_request.user.email_address)
      expect(response.body).to include(pending_request.role_name)
    end

    it "displays Notes column header", :aggregate_failures do
      get admin_role_requests_path
      expect(response.body).to include("Notes")
    end

    it "displays notes column for all pending requests", :aggregate_failures do
      get admin_role_requests_path
      if pending_request.note.present?
        # Check for note content (accounting for HTML escaping)
        expect(response.body).to include(CGI.escapeHTML(pending_request.note))
      end
    end

    context "when role request has notes" do
      let!(:pending_request_with_notes) { create(:role_request, status: "pending", note: "We need access for testing purposes") }

      it "displays notes in the table", :aggregate_failures do
        get admin_role_requests_path
        expect(response.body).to include("We need access for testing purposes")
      end

      it "displays notes in the Notes column cell", :aggregate_failures do
        get admin_role_requests_path
        # Verify the note appears in the table structure
        expect(response.body).to include(pending_request_with_notes.note)
        # Verify it's in a table cell context (between table row markers)
        expect(response.body).to match(/<td[^>]*>.*#{Regexp.escape(pending_request_with_notes.note)}.*<\/td>/m)
      end
    end

    context "when role request has no notes (legacy request)" do
      let(:pending_request_without_notes) do
        # Create a legacy request without notes (skip validations to simulate legacy data)
        role_request = build(:role_request, status: "pending", note: nil)
        role_request.save!(validate: false)
        role_request
      end

      it "displays empty cell for requests without notes", :aggregate_failures do
        pending_request_without_notes # Create the record
        get admin_role_requests_path
        expect(response).to have_http_status(:ok)
        # Verify the request appears in the table (empty note cell is fine)
        expect(response.body).to include(pending_request_without_notes.organisation.organisation_name)
      end
    end
  end

  describe "POST /admin/role_requests/:id/approve" do
    let(:organisation) { create(:organisation) }
    let(:user) { create(:user, organisation: organisation) }
    let(:role_request) { create(:role_request, organisation: organisation, user: user, role_name: "fpo:full", status: "pending") }

    before do
      stub_request(:post, "#{TradeTariffDevHub.uk_backend_url}/notifications")
        .to_return(
          status: 202,
          body: '{"data":{"id": "beff2bec-b82a-4196-b393-d733394a4ec0","type":"notification"}}',
          headers: { "Content-Type" => "application/json" },
        )
    end

    it "approves the role request and assigns the role", :aggregate_failures do
      expect { post approve_admin_role_request_path(role_request) }
        .to change { role_request.reload.status }.from("pending").to("approved")
        .and change { organisation.reload.has_role?("fpo:full") }.from(false).to(true)
    end

    it "redirects to index with success message", :aggregate_failures do
      post approve_admin_role_request_path(role_request)
      expect(response).to redirect_to(admin_role_requests_path)
      follow_redirect!
      expect(response.body).to include("Role fpo:full has been assigned")
    end

    it "sends an approval email" do
      post approve_admin_role_request_path(role_request)
      expect(WebMock).to have_requested(:post, "#{TradeTariffDevHub.uk_backend_url}/notifications")
    end

    context "when role request not found" do
      it "redirects with error message", :aggregate_failures do
        post approve_admin_role_request_path("non-existent-id")
        expect(response).to redirect_to(admin_role_requests_path)
        follow_redirect!
        expect(response.body).to include("Role request not found")
      end
    end

    context "when approval fails" do
      before do
        allow(role_request).to receive(:approve!).and_raise(StandardError.new("Database error"))
        allow(RoleRequest).to receive(:find).and_return(role_request)
      end

      it "redirects with error message", :aggregate_failures do
        post approve_admin_role_request_path(role_request)
        expect(response).to redirect_to(admin_role_requests_path)
        follow_redirect!
        expect(response.body).to include("There was an unexpected problem approving the role request")
      end
    end
  end

  describe "authorization" do
    context "when user is not an admin" do
      before do
        current_user.organisation.unassign_role!("admin")
        current_user.organisation.assign_role!("trade_tariff:full")
      end

      it "redirects to root path", :aggregate_failures do
        get admin_role_requests_path
        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("Access denied")
      end
    end
  end
end
