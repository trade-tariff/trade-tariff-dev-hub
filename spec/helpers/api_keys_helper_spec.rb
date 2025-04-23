require "rails_helper"

RSpec.describe ApiKeysHelper, type: :helper do
  let(:api_key) { FactoryBot.create(:api_key) }

  describe "#mask_api_key" do
    it "masks the key" do
      expected = "****#{api_key.api_key_id[-4..]}"
      expect(helper.mask_api_key(api_key)).to eq(expected)
    end
  end

  describe "#api_key_status" do
    it "returns active" do
      expect(helper.api_key_status(api_key)).to eq("Active")
    end

    it "returns revoked with date" do
      api_key.update!(enabled: false)
      revoked_datetime = api_key.updated_at.strftime("%d %B %Y")

      expect(helper.api_key_status(api_key)).to eq("Revoked on #{revoked_datetime}")
    end
  end

  describe "#creation_date" do
    it "returns 'Today' if created today" do
      expect(helper.creation_date(api_key)).to eq("Today")
    end

    it "returns full date if created before today" do
      api_key.created_at = Date.parse("2025-04-08 10:56:20.493373000 UTC +00:00")
      expect(helper.creation_date(api_key)).to eq("08 April 2025")
    end
  end
end
