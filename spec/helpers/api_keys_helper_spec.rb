require "rails_helper"

RSpec.describe ApiKeysHelper, type: :helper do
  describe "masks api key with asterisks" do
    it "receives an api key and returns the masked version" do
      expect(helper.mask_api_key("5aec6aeb-e72d-43b8-a0bf-47ace6cc1a31")).to eq("****1a31")
    end
  end

  describe "set api key status" do
    before do
      @api_key = FactoryBot.create(:api_key)
    end

    it "enabled attrivute defaults to true" do
      expect(@api_key.enabled?).to eq(true)
    end

    it "to Active" do
      expect(helper.api_key_status(@api_key)).to eq("Active")
    end

    it "to Revoked" do
      @api_key.enabled = false
      @api_key.save
      revoked_datetime = @api_key.updated_at.strftime("%d %B %Y")

      expect(helper.api_key_status(@api_key)).to eq("Revoked on " + revoked_datetime)
    end
  end

  describe "set api key creation date" do
    before do
      @api_key = FactoryBot.create(:api_key)
    end

    it "returns 'Today' if created today" do
      expect(helper.creation_date(@api_key)).to eq("Today")
    end

    it "returns full date if created before today" do
      @api_key.created_at = "2025-04-08 10:56:20.493373000 UTC +00:00".to_datetime
      expect(helper.creation_date(@api_key)).to eq("08 April 2025")
    end
  end
end
