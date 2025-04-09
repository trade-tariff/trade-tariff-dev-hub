require 'rails_helper'

RSpec.describe "ApiKeys", type: :request do
  describe "GET /index" do
    api_keys = ApiKey.all

    it "returns a list of api keys" do
      get "/dashboard"
      expect(response).to be_successful
    end
  end

  describe "GET /new" do
    it "renders 'new' template" do
      get "/dashboard/new"
      expect(response).to be_successful
    end
  end

  describe "GET /show" do
    context "Api key creation is successful" do
      it "renders 'create' template" do
        get "/dashboard/create", params: { success: true }

        expect(response).to be_successful
        expect(response).to render_template("create")
      end
    end

    context "Api key creation is unsuccessful" do
      it "redirects to error page" do
        get "/dashboard/create"

        expect(response).not_to be_successful
        expect(response).to redirect_to(not_found_path)
      end
    end
  end

  describe "GET /update" do
    let(:api_key) { create(:api_key) }

    context "Api key is enabled" do
      it "renders 'revoke' template" do
        get "/dashboard/#{api_key.id}/revoke"

        binding.pry

        expect(response).to be_successful
        expect(response).to render_template("revoke")
      end
    end

     context "Api key is disabled" do
      it "renders 'delete' template" do
        api_key.update(enabled: false)

        get "/dashboard/#{api_key.id}/delete"

        expect(response).to be_successful
        expect(response).to render_template("delete")
      end
    end
   end
end
