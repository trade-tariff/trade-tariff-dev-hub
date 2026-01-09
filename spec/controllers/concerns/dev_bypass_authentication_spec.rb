# frozen_string_literal: true

RSpec.describe DevBypassAuthentication, type: :controller do
  # Create a test controller that includes the concern
  concern_class = described_class

  controller(ApplicationController) do
    include concern_class

    before_action :require_dev_bypass_authentication

    def index
      render plain: "OK"
    end
  end

  before do
    routes.draw do
      get "index" => "anonymous#index"
      get "/dev/login", to: "dev_auth#new", as: :dev_login
      post "/dev/login", to: "dev_auth#create"
      delete "/dev/logout", to: "dev_auth#destroy", as: :dev_logout
    end

    allow(TradeTariffDevHub).to receive(:dev_bypass_auth_enabled?).and_return(true)
  end

  describe "#dev_bypass_user_type" do
    context "when dev bypass is enabled" do
      it "returns admin user type when admin type in session" do
        session[:dev_bypass] = DevBypassAuthentication::USER_TYPE_ADMIN
        expect(controller.send(:dev_bypass_user_type)).to eq(DevBypassAuthentication::USER_TYPE_ADMIN)
      end

      it "returns user type when user type in session" do
        session[:dev_bypass] = DevBypassAuthentication::USER_TYPE_USER
        expect(controller.send(:dev_bypass_user_type)).to eq(DevBypassAuthentication::USER_TYPE_USER)
      end

      it "returns nil when invalid user type in session" do
        session[:dev_bypass] = "invalid_type"
        expect(controller.send(:dev_bypass_user_type)).to be_nil
      end

      it "returns nil when blank session" do
        session[:dev_bypass] = ""
        expect(controller.send(:dev_bypass_user_type)).to be_nil
      end

      it "returns nil when no session" do
        expect(controller.send(:dev_bypass_user_type)).to be_nil
      end
    end

    context "when dev bypass is disabled" do
      before do
        allow(TradeTariffDevHub).to receive(:dev_bypass_auth_enabled?).and_return(false)
        session[:dev_bypass] = DevBypassAuthentication::USER_TYPE_ADMIN
      end

      it "returns nil" do
        expect(controller.send(:dev_bypass_user_type)).to be_nil
      end
    end
  end

  describe "#find_or_create_dev_user" do
    context "with admin user type" do
      it "creates or finds admin user", :aggregate_failures do
        user = controller.send(:find_or_create_dev_user, DevBypassAuthentication::USER_TYPE_ADMIN)

        expect(user).to be_persisted
        expect(user.email_address).to eq("dev-admin@transformuk.com")
        expect(user.organisation.organisation_name).to eq("Admin Dev Org")
        expect(user.organisation.admin?).to be true
      end

      it "assigns admin role to organisation" do
        user = controller.send(:find_or_create_dev_user, DevBypassAuthentication::USER_TYPE_ADMIN)

        expect(user.organisation.has_role?("admin")).to be true
      end
    end

    context "with admin user type when user already exists" do
      let!(:existing_user) do
        User.find_or_create_by!(email_address: "dev-admin@transformuk.com") do |u|
          u.user_id = SecureRandom.uuid
          u.organisation = Organisation.find_or_create_by!(organisation_name: "Admin Dev Org")
        end
      end

      it "returns existing user" do
        user = controller.send(:find_or_create_dev_user, DevBypassAuthentication::USER_TYPE_ADMIN)

        expect(user).to eq(existing_user)
      end

      it "ensures organisation has admin role" do
        existing_user.organisation.unassign_role!("admin")
        controller.send(:find_or_create_dev_user, DevBypassAuthentication::USER_TYPE_ADMIN)

        expect(existing_user.organisation.reload.admin?).to be true
      end

      it "uses existing organisation even when name has been changed", :aggregate_failures do
        original_org_id = existing_user.organisation.id
        existing_user.organisation.update!(organisation_name: "Admin Dev Org test")

        user = controller.send(:find_or_create_dev_user, DevBypassAuthentication::USER_TYPE_ADMIN)

        expect(user.organisation.id).to eq(original_org_id)
        expect(user.organisation.organisation_name).to eq("Admin Dev Org test")
        expect(Organisation.where(organisation_name: "Admin Dev Org").count).to eq(0)
      end
    end

    context "with user type" do
      it "creates or finds regular user", :aggregate_failures do
        user = controller.send(:find_or_create_dev_user, DevBypassAuthentication::USER_TYPE_USER)

        expect(user).to be_persisted
        expect(user.email_address).to eq("dev@transformuk.com")
        expect(user.organisation.organisation_name).to eq("User Dev Org")
      end

      it "assigns trade_tariff:full and fpo:full roles to organisation", :aggregate_failures do
        user = controller.send(:find_or_create_dev_user, DevBypassAuthentication::USER_TYPE_USER)

        expect(user.organisation.has_role?("trade_tariff:full")).to be true
        expect(user.organisation.has_role?("fpo:full")).to be true
      end
    end

    context "with user type when user already exists" do
      let!(:existing_user) do
        User.find_or_create_by!(email_address: "dev@transformuk.com") do |u|
          u.user_id = SecureRandom.uuid
          u.organisation = Organisation.find_or_create_by!(organisation_name: "User Dev Org")
        end
      end

      it "returns existing user" do
        user = controller.send(:find_or_create_dev_user, DevBypassAuthentication::USER_TYPE_USER)

        expect(user).to eq(existing_user)
      end

      it "ensures organisation has required roles", :aggregate_failures do
        existing_user.organisation.unassign_role!("trade_tariff:full")
        controller.send(:find_or_create_dev_user, DevBypassAuthentication::USER_TYPE_USER)

        expect(existing_user.organisation.reload.has_role?("trade_tariff:full")).to be true
        expect(existing_user.organisation.has_role?("fpo:full")).to be true
      end

      it "uses existing organisation even when name has been changed", :aggregate_failures do
        original_org_id = existing_user.organisation.id
        existing_user.organisation.update!(organisation_name: "User Dev Org test")

        user = controller.send(:find_or_create_dev_user, DevBypassAuthentication::USER_TYPE_USER)

        expect(user.organisation.id).to eq(original_org_id)
        expect(user.organisation.organisation_name).to eq("User Dev Org test")
        expect(Organisation.where(organisation_name: "User Dev Org").count).to eq(0)
      end
    end

    context "with invalid user type" do
      it "returns nil" do
        user = controller.send(:find_or_create_dev_user, "invalid_type")

        expect(user).to be_nil
      end

      it "does not create any users" do
        expect {
          controller.send(:find_or_create_dev_user, "invalid_type")
        }.not_to change(User, :count)
      end
    end
  end

  describe "#current_user_with_dev_bypass" do
    it "returns a user when dev bypass is enabled and valid session exists", :aggregate_failures do
      session[:dev_bypass] = DevBypassAuthentication::USER_TYPE_USER
      user = controller.send(:current_user_with_dev_bypass)

      expect(user).to be_a(User)
      expect(user.email_address).to eq("dev@transformuk.com")
    end

    it "returns nil when dev bypass is enabled but no valid session" do
      expect(controller.send(:current_user_with_dev_bypass)).to be_nil
    end

    it "returns nil when dev bypass is disabled" do
      allow(TradeTariffDevHub).to receive(:dev_bypass_auth_enabled?).and_return(false)
      session[:dev_bypass] = DevBypassAuthentication::USER_TYPE_USER

      expect(controller.send(:current_user_with_dev_bypass)).to be_nil
    end
  end

  describe "#organisation_with_dev_bypass" do
    it "returns the user's organisation when dev bypass is enabled and valid session exists", :aggregate_failures do
      session[:dev_bypass] = DevBypassAuthentication::USER_TYPE_USER
      org = controller.send(:organisation_with_dev_bypass)

      expect(org).to be_an(Organisation)
      expect(org.organisation_name).to eq("User Dev Org")
    end

    it "returns nil when dev bypass is enabled but no valid session" do
      expect(controller.send(:organisation_with_dev_bypass)).to be_nil
    end
  end
end
