RSpec.describe "Role Requests", type: :request do
  include_context "with authenticated user"

  before do
    current_user.organisation.assign_role!("trade_tariff:full")
  end

  describe "GET /role_requests/new" do
    it "renders the new role request form", :aggregate_failures do
      get new_role_request_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Request access")
      expect(response.body).to include("Note")
      expect(response.body).not_to include("Note (optional)")
    end

    context "when FPO role is available" do
      it "displays FPO-specific information in inset box and includes FPO hint content (hidden by default)", :aggregate_failures do
        get new_role_request_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("FPO (Fast Parcel Operator) API access")
        expect(response.body).to include("UK Carrier Scheme (UKC)–registered organisations")
        # FPO hint content is in the HTML but hidden by default, shown only when FPO is selected
        expect(response.body).to include("fpo-hint-content")
        expect(response.body).to include("The FPO (Fast Parcel Operator) Commodity Code Identification Tool API is a free-to-use API")
      end
    end

    context "when FPO role is not available" do
      before do
        current_user.organisation.assign_role!("fpo:full")
      end

      it "does not display FPO-specific information in inset box or hint", :aggregate_failures do
        get new_role_request_path
        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include("FPO (Fast Parcel Operator) API access")
        expect(response.body).not_to include("fpo-hint-content")
      end
    end

    context "when user is an admin" do
      before do
        current_user.organisation.assign_role!("admin")
      end

      it "redirects to organisation page", :aggregate_failures do
        get new_role_request_path
        expect(response).to redirect_to(organisation_path(current_user.organisation))
        follow_redirect!
        expect(response.body).to include("Admins already have access to all roles")
      end
    end

    context "when no available roles" do
      before do
        current_user.organisation.assign_role!("fpo:full")
        current_user.organisation.assign_role!("spimm:full")
      end

      it "redirects to organisation page", :aggregate_failures do
        get new_role_request_path
        expect(response).to redirect_to(organisation_path(current_user.organisation))
        follow_redirect!
        expect(response.body).to include("No additional roles available to request.")
      end
    end
  end

  describe "POST /role_requests" do
    let(:params) do
      {
        role_request: {
          role_name: "fpo:full",
          note: "I need access to manage FPO API keys",
        },
      }
    end

    before do
      stub_request(:post, "#{TradeTariffDevHub.uk_backend_url}/notifications")
        .to_return(
          status: 202,
          body: '{"data":{"id": "beff2bec-b82a-4196-b393-d733394a4ec0","type":"notification"}}',
          headers: { "Content-Type" => "application/json" },
        )
    end

    it "creates a new role request", :aggregate_failures do
      expect { post role_requests_path, params: params }
        .to change { RoleRequest.where(role_name: "fpo:full", organisation: current_user.organisation).count }.by(1)

      role_request = RoleRequest.last
      expect(role_request.user).to eq(current_user)
      expect(role_request.organisation).to eq(current_user.organisation)
      expect(role_request.role_name).to eq("fpo:full")
    end

    it "redirects to organisation page with success message", :aggregate_failures do
      post role_requests_path, params: params
      expect(response).to redirect_to(organisation_path(current_user.organisation))
      follow_redirect!
      expect(response.body).to include("Your access request has been submitted successfully")
    end

    it "sends a role request email" do
      post role_requests_path, params: params
      expect(WebMock).to have_requested(:post, "#{TradeTariffDevHub.uk_backend_url}/notifications")
    end

    context "with invalid parameters" do
      # rubocop:disable RSpec/NestedGroups
      context "when role_name is invalid" do
        let(:params) do
          {
            role_request: {
              role_name: "invalid:role",
              note: "Some note",
            },
          }
        end

        it "does not create a role request" do
          expect { post role_requests_path, params: params }
            .not_to change(RoleRequest, :count)
        end

        it "re-renders the new template with errors", :aggregate_failures do
          post role_requests_path, params: params
          expect(response).to have_http_status(:ok)
          expect(response.body).to include("is not a valid assignable role")
        end
      end

      context "when note is blank" do
        let(:params) do
          {
            role_request: {
              role_name: "fpo:full",
              note: "",
            },
          }
        end

        it "does not create a role request" do
          expect { post role_requests_path, params: params }
            .not_to change(RoleRequest, :count)
        end

        it "re-renders the new template with errors", :aggregate_failures do
          post role_requests_path, params: params
          expect(response).to have_http_status(:ok)
          expect(response.body).to include("You must provide information about why you need access to this role")
        end
      end

      context "when note is missing" do
        let(:params) do
          {
            role_request: {
              role_name: "fpo:full",
            },
          }
        end

        it "does not create a role request" do
          expect { post role_requests_path, params: params }
            .not_to change(RoleRequest, :count)
        end

        it "re-renders the new template with errors", :aggregate_failures do
          post role_requests_path, params: params
          expect(response).to have_http_status(:ok)
          expect(response.body).to include("You must provide information about why you need access to this role")
        end
      end
      # rubocop:enable RSpec/NestedGroups
    end

    context "when duplicate pending request exists" do
      before do
        create(:role_request, organisation: current_user.organisation, user: current_user, role_name: "fpo:full", status: "pending")
      end

      it "does not create a duplicate request", :aggregate_failures do
        expect { post role_requests_path, params: params }
          .not_to change(RoleRequest, :count)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("has already been requested and is pending")
      end
    end

    context "when note exceeds 200 characters" do
      let(:params) do
        {
          role_request: {
            role_name: "fpo:full",
            note: "a" * 201,
          },
        }
      end

      it "does not create a role request", :aggregate_failures do
        expect { post role_requests_path, params: params }
          .not_to change(RoleRequest, :count)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("must be 200 characters or fewer")
      end
    end
  end
end
