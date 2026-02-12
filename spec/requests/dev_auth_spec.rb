# frozen_string_literal: true

RSpec.describe "Dev Auth", type: :request do
  before do
    allow(TradeTariffDevHub).to receive_messages(
      dev_bypass_auth_enabled?: true,
      dev_bypass_admin_password: "admin-password",
      dev_bypass_user_password: "user-password",
      identity_consumer_url: "https://identity.example.com",
    )
    # Reload routes to ensure dev routes are available
    Rails.application.reload_routes!
  end

  describe "GET /dev/login" do
    it "renders the login form when user is not logged in", :aggregate_failures do
      get dev_login_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Dev Login")
      expect(response.body).to include("Enter password")
      expect(response.body).to include("This is a development-only bypass")
    end

    it "redirects to default path when user is already logged in via dev bypass" do
      # First login to establish session
      post dev_login_path, params: { password: "user-password" }
      follow_redirect!
      # Get the user's organisation
      user = User.find_by(email_address: "dev@transformuk.com")
      # Then try to access login page again - should redirect
      get dev_login_path
      expect(response).to redirect_to(organisation_path(user.organisation))
    end

    it "shows link to use real identity service", :aggregate_failures do
      get dev_login_path
      expect(response.body).to include("Use real identity service")
      expect(response.body).to include('href="https://identity.example.com"')
    end
  end

  describe "POST /dev/login" do
    it "sets session and redirects to organisation page with valid admin password", :aggregate_failures do
      post dev_login_path, params: { password: "admin-password" }
      user = User.find_by(email_address: "dev-admin@transformuk.com")
      expect(response).to redirect_to(organisation_path(user.organisation))
      # Verify session is set by checking we can access the page
      follow_redirect!
      expect(response).to have_http_status(:ok)
    end

    it "redirects to organisation page even when return_to is set", :aggregate_failures do
      # Try to access a protected page while not logged in - this sets return_to
      get api_keys_path
      expect(response).to redirect_to(dev_login_path)
      # Now login - should always redirect to organisation page, ignoring return_to
      post dev_login_path, params: { password: "admin-password" }
      user = User.find_by(email_address: "dev-admin@transformuk.com")
      expect(response).to redirect_to(organisation_path(user.organisation))
    end

    it "sets session and redirects to organisation page with valid user password", :aggregate_failures do
      post dev_login_path, params: { password: "user-password" }
      user = User.find_by(email_address: "dev@transformuk.com")
      expect(response).to redirect_to(organisation_path(user.organisation))
      # Verify session is set by checking we can access the page
      follow_redirect!
      expect(response).to have_http_status(:ok)
    end

    it "renders new template with error for invalid password", :aggregate_failures do
      post dev_login_path, params: { password: "wrong-password" }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Dev Login")
      expect(response.body).to include("Invalid password")
    end

    it "does not set session for invalid password" do
      post dev_login_path, params: { password: "wrong-password" }
      # Verify session is not set by trying to access a protected page
      get api_keys_path
      expect(response).to redirect_to(dev_login_path)
    end

    it "renders new template with error for blank password", :aggregate_failures do
      post dev_login_path, params: { password: "" }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Invalid password")
    end

    it "renders new template with error for nil password", :aggregate_failures do
      post dev_login_path, params: { password: nil }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Invalid password")
    end
  end

  describe "DELETE /dev/logout" do
    before do
      # First login to establish session
      post dev_login_path, params: { password: "user-password" }
      follow_redirect!
    end

    it "clears the dev bypass session", :aggregate_failures do
      delete dev_logout_path
      expect(response).to redirect_to(root_path)
      # After logout, try to access a protected page - should redirect to login
      get api_keys_path
      expect(response).to redirect_to(dev_login_path)
    end

    it "redirects to root path" do
      delete dev_logout_path
      expect(response).to redirect_to(root_path)
    end

    it "sets a notice message", :aggregate_failures do
      delete dev_logout_path
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("You have been logged out")
    end
  end
end
